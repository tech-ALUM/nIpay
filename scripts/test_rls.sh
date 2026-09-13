#!/usr/bin/env bash
# Test di isolamento RLS (M-ACC2) contro il progetto Supabase reale.
#
# Non serve un secondo utente reale: un wallet "fantasma" con
# owner_user_id fittizio va seminato a mano una volta (bypassa RLS
# perché lanciato come postgres dal SQL Editor):
#
#   insert into wallets (owner_user_id, name, color_hex)
#   values ('7baad097-c2da-4baf-9484-bd766581e72e', 'ghost-wallet', '#000000');
#
# Uso:
#   SUPABASE_URL=... SUPABASE_ANON_KEY=... TEST_USER_EMAIL=... TEST_USER_PASSWORD=... \
#     ./scripts/test_rls.sh
#
# Credenziali mai hardcoded qui: sono dati di un account di test throwaway,
# non c'entrano con lo schema o la logica in sé.
set -euo pipefail

: "${SUPABASE_URL:?serve SUPABASE_URL}"
: "${SUPABASE_ANON_KEY:?serve SUPABASE_ANON_KEY}"
: "${TEST_USER_EMAIL:?serve TEST_USER_EMAIL (utente di test già confermato via email)}"
: "${TEST_USER_PASSWORD:?serve TEST_USER_PASSWORD}"

GHOST_OWNER_ID="7baad097-c2da-4baf-9484-bd766581e72e"
PASS=0
FAIL=0

check() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then
    echo "PASS  $desc"
    PASS=$((PASS + 1))
  else
    echo "FAIL  $desc (atteso: $expected, ricevuto: $actual)"
    FAIL=$((FAIL + 1))
  fi
}

echo "== Login utente di test =="
LOGIN_RESP=$(curl -s -X POST "$SUPABASE_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $SUPABASE_ANON_KEY" -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_USER_EMAIL\",\"password\":\"$TEST_USER_PASSWORD\"}")
ACCESS_TOKEN=$(echo "$LOGIN_RESP" | python3 -c "import json,sys; print(json.load(sys.stdin).get('access_token',''))")
USER_ID=$(echo "$LOGIN_RESP" | python3 -c "import json,sys; print(json.load(sys.stdin).get('user',{}).get('id',''))")

if [[ -z "$ACCESS_TOKEN" ]]; then
  echo "Login fallito, risposta: $LOGIN_RESP" >&2
  exit 1
fi
echo "Loggato come user_id=$USER_ID"

auth_curl() {
  curl -s "$@" -H "apikey: $SUPABASE_ANON_KEY" -H "Authorization: Bearer $ACCESS_TOKEN"
}
anon_curl() {
  curl -s "$@" -H "apikey: $SUPABASE_ANON_KEY"
}

echo
echo "== 1. Utente autenticato non vede il wallet fantasma =="
RESP=$(auth_curl "$SUPABASE_URL/rest/v1/wallets?owner_user_id=eq.$GHOST_OWNER_ID&select=id")
check "select su wallet fantasma restituisce vuoto" "[]" "$RESP"

echo
echo "== 2. Utente autenticato crea un proprio wallet =="
CREATE_RESP=$(auth_curl -X POST "$SUPABASE_URL/rest/v1/wallets" \
  -H "Content-Type: application/json" -H "Prefer: return=representation" \
  -d "{\"owner_user_id\":\"$USER_ID\",\"name\":\"test-own\",\"color_hex\":\"#111111\"}")
OWN_WALLET_ID=$(echo "$CREATE_RESP" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d[0]['id'] if isinstance(d,list) and d else '')")
if [[ -n "$OWN_WALLET_ID" ]]; then
  echo "PASS  insert del proprio wallet riuscito (id=$OWN_WALLET_ID)"
  PASS=$((PASS + 1))
else
  echo "FAIL  insert del proprio wallet fallito: $CREATE_RESP"
  FAIL=$((FAIL + 1))
fi

echo
echo "== 3. Utente autenticato NON può creare un wallet intestato ad altri =="
HTTP_CODE=$(curl -s -o /tmp/rls_test_resp.json -w "%{http_code}" -X POST "$SUPABASE_URL/rest/v1/wallets" \
  -H "apikey: $SUPABASE_ANON_KEY" -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"owner_user_id\":\"$GHOST_OWNER_ID\",\"name\":\"hijack\",\"color_hex\":\"#222222\"}")
check "insert con owner_user_id altrui viene respinto (403)" "403" "$HTTP_CODE"

echo
echo "== 4. Utente autenticato NON può modificare il wallet fantasma =="
UPDATE_RESP=$(auth_curl -X PATCH "$SUPABASE_URL/rest/v1/wallets?owner_user_id=eq.$GHOST_OWNER_ID" \
  -H "Content-Type: application/json" -H "Prefer: return=representation" \
  -d '{"name":"hacked"}')
check "update sul wallet fantasma non modifica righe" "[]" "$UPDATE_RESP"

echo
echo "== 5. Utente autenticato NON può cancellare il wallet fantasma =="
DELETE_RESP=$(auth_curl -X DELETE "$SUPABASE_URL/rest/v1/wallets?owner_user_id=eq.$GHOST_OWNER_ID" \
  -H "Prefer: return=representation")
check "delete sul wallet fantasma non cancella righe" "[]" "$DELETE_RESP"

echo
echo "== 6. Client non autenticato resta bloccato (anon key, nessun token) =="
ANON_SELECT=$(anon_curl "$SUPABASE_URL/rest/v1/wallets?select=id&limit=1")
check "select anonima su wallets restituisce vuoto" "[]" "$ANON_SELECT"

echo
echo "== Pulizia: rimuovo il wallet di test creato al passo 2 =="
if [[ -n "$OWN_WALLET_ID" ]]; then
  auth_curl -X DELETE "$SUPABASE_URL/rest/v1/wallets?id=eq.$OWN_WALLET_ID" > /dev/null
  echo "wallet di test $OWN_WALLET_ID rimosso"
fi

echo
echo "== Risultato: $PASS passati, $FAIL falliti =="
[[ "$FAIL" -eq 0 ]]

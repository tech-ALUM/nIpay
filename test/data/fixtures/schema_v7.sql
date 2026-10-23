CREATE TABLE "wallets" ("id" TEXT NOT NULL, "created_at" TEXT NOT NULL, "updated_at" TEXT NOT NULL, "deleted_at" TEXT NULL, "name" TEXT NOT NULL, "color_hex" TEXT NOT NULL, "icon" TEXT NOT NULL DEFAULT 'wallet', "initial_balance_cents" INTEGER NOT NULL DEFAULT 0, "archived_at" TEXT NULL, "position" INTEGER NOT NULL DEFAULT 0, "currency" TEXT NOT NULL DEFAULT 'EUR', PRIMARY KEY ("id"));
CREATE TABLE "categories" ("id" TEXT NOT NULL, "created_at" TEXT NOT NULL, "updated_at" TEXT NOT NULL, "deleted_at" TEXT NULL, "wallet_id" TEXT NULL REFERENCES wallets (id), "name" TEXT NOT NULL, "icon" TEXT NOT NULL, "color_hex" TEXT NOT NULL, "kind" TEXT NOT NULL, "parent_id" TEXT NULL REFERENCES categories (id), "sort_order" INTEGER NOT NULL DEFAULT 0, "is_default" INTEGER NOT NULL DEFAULT 0 CHECK ("is_default" IN (0, 1)), PRIMARY KEY ("id"));
CREATE TABLE "transactions" ("id" TEXT NOT NULL, "created_at" TEXT NOT NULL, "updated_at" TEXT NOT NULL, "deleted_at" TEXT NULL, "type" TEXT NOT NULL, "amount_cents" INTEGER NOT NULL, "date" TEXT NOT NULL, "wallet_id" TEXT NOT NULL REFERENCES wallets (id), "wallet_to_id" TEXT NULL REFERENCES wallets (id), "category_id" TEXT NULL REFERENCES categories (id), "description" TEXT NOT NULL DEFAULT '', "note" TEXT NULL, "entry_currency" TEXT NULL, "entry_amount_cents" INTEGER NULL, "amount_cents_to" INTEGER NULL, PRIMARY KEY ("id"));
CREATE TABLE "tags" ("id" TEXT NOT NULL, "created_at" TEXT NOT NULL, "updated_at" TEXT NOT NULL, "deleted_at" TEXT NULL, "wallet_id" TEXT NULL REFERENCES wallets (id), "name" TEXT NOT NULL, PRIMARY KEY ("id"));
CREATE TABLE "transaction_tags" ("transaction_id" TEXT NOT NULL REFERENCES transactions (id), "tag_id" TEXT NOT NULL REFERENCES tags (id), "created_at" TEXT NOT NULL, "updated_at" TEXT NOT NULL, "deleted_at" TEXT NULL, PRIMARY KEY ("transaction_id", "tag_id"));
CREATE TABLE "custom_field_defs" ("id" TEXT NOT NULL, "created_at" TEXT NOT NULL, "updated_at" TEXT NOT NULL, "deleted_at" TEXT NULL, "wallet_id" TEXT NULL REFERENCES wallets (id), "name" TEXT NOT NULL, "type" TEXT NOT NULL, "expense_report_only" INTEGER NOT NULL DEFAULT 0 CHECK ("expense_report_only" IN (0, 1)), "options" TEXT NULL, "sort_order" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("id"));
CREATE TABLE "custom_field_values" ("transaction_id" TEXT NOT NULL REFERENCES transactions (id), "field_id" TEXT NOT NULL REFERENCES custom_field_defs (id), "value" TEXT NOT NULL, "updated_at" TEXT NOT NULL, PRIMARY KEY ("transaction_id", "field_id"));
CREATE TABLE "budgets" ("id" TEXT NOT NULL, "created_at" TEXT NOT NULL, "updated_at" TEXT NOT NULL, "deleted_at" TEXT NULL, "wallet_id" TEXT NULL REFERENCES wallets (id), "category_id" TEXT NOT NULL REFERENCES categories (id), "limit_cents" INTEGER NOT NULL, PRIMARY KEY ("id"));
CREATE TABLE "recurring_rules" ("id" TEXT NOT NULL, "created_at" TEXT NOT NULL, "updated_at" TEXT NOT NULL, "deleted_at" TEXT NULL, "wallet_id" TEXT NOT NULL REFERENCES wallets (id), "category_id" TEXT NULL REFERENCES categories (id), "type" TEXT NOT NULL, "amount_cents" INTEGER NOT NULL, "description" TEXT NOT NULL DEFAULT '', "frequency" TEXT NOT NULL, "start_at" TEXT NOT NULL, "next_run_at" TEXT NOT NULL, "end_at" TEXT NULL, "paused_at" TEXT NULL, PRIMARY KEY ("id"));
CREATE TABLE "attachments" ("id" TEXT NOT NULL, "created_at" TEXT NOT NULL, "updated_at" TEXT NOT NULL, "deleted_at" TEXT NULL, "transaction_id" TEXT NOT NULL REFERENCES transactions (id), "relative_path" TEXT NOT NULL, "mime_type" TEXT NOT NULL, PRIMARY KEY ("id"));
CREATE TABLE "dashboard_cards" ("id" TEXT NOT NULL, "created_at" TEXT NOT NULL, "updated_at" TEXT NOT NULL, "deleted_at" TEXT NULL, "wallet_id" TEXT NULL REFERENCES wallets (id), "type" TEXT NOT NULL, "position" INTEGER NOT NULL, "config_json" TEXT NOT NULL DEFAULT '{}', PRIMARY KEY ("id"));
CREATE TABLE "cost_centers" ("id" TEXT NOT NULL, "created_at" TEXT NOT NULL, "updated_at" TEXT NOT NULL, "deleted_at" TEXT NULL, "wallet_id" TEXT NULL REFERENCES wallets (id), "name" TEXT NOT NULL, PRIMARY KEY ("id"));
CREATE TABLE "expense_reports" ("id" TEXT NOT NULL, "created_at" TEXT NOT NULL, "updated_at" TEXT NOT NULL, "deleted_at" TEXT NULL, "wallet_id" TEXT NULL REFERENCES wallets (id), "name" TEXT NOT NULL, "date_from" TEXT NOT NULL, "date_to" TEXT NOT NULL, "status" TEXT NOT NULL, "reimburse_tx_id" TEXT NULL REFERENCES transactions (id), PRIMARY KEY ("id"));
CREATE TABLE "expense_report_entries" ("transaction_id" TEXT NOT NULL REFERENCES transactions (id), "cost_center_id" TEXT NULL REFERENCES cost_centers (id), "reimbursable" INTEGER NOT NULL DEFAULT 1 CHECK ("reimbursable" IN (0, 1)), "e_invoice" INTEGER NOT NULL DEFAULT 0 CHECK ("e_invoice" IN (0, 1)), "report_id" TEXT NULL REFERENCES expense_reports (id), "updated_at" TEXT NOT NULL, "deleted_at" TEXT NULL, PRIMARY KEY ("transaction_id"));
CREATE TABLE "sync_states" ("user_id" TEXT NOT NULL, "last_pushed_at" TEXT NOT NULL, "last_pulled_at" TEXT NOT NULL, "user_email" TEXT NULL, "last_success_at" TEXT NULL, "last_error" TEXT NULL, "pending_issues" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("user_id"));
CREATE TABLE "sync_cursors" ("user_id" TEXT NOT NULL, "sync_table" TEXT NOT NULL, "last_updated_at" TEXT NOT NULL, PRIMARY KEY ("user_id", "sync_table"));
CREATE TABLE "sync_outbox" ("seq" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "sync_table" TEXT NOT NULL, "row_key" TEXT NOT NULL, UNIQUE ("sync_table", "row_key"));
CREATE UNIQUE INDEX budgets_live_category ON budgets (category_id) WHERE deleted_at IS NULL;
CREATE TRIGGER sync_outbox_wallets_ins
          AFTER INSERT ON wallets
          BEGIN
            DELETE FROM sync_outbox
              WHERE sync_table = 'wallets' AND row_key = NEW.id;
            INSERT INTO sync_outbox (sync_table, row_key) VALUES ('wallets', NEW.id);
          END;
CREATE TRIGGER sync_outbox_wallets_upd
          AFTER UPDATE ON wallets
          BEGIN
            DELETE FROM sync_outbox
              WHERE sync_table = 'wallets' AND row_key = NEW.id;
            INSERT INTO sync_outbox (sync_table, row_key) VALUES ('wallets', NEW.id);
          END;
CREATE TRIGGER sync_outbox_categories_ins
          AFTER INSERT ON categories
          BEGIN
            DELETE FROM sync_outbox
              WHERE sync_table = 'categories' AND row_key = NEW.id;
            INSERT INTO sync_outbox (sync_table, row_key) VALUES ('categories', NEW.id);
          END;
CREATE TRIGGER sync_outbox_categories_upd
          AFTER UPDATE ON categories
          BEGIN
            DELETE FROM sync_outbox
              WHERE sync_table = 'categories' AND row_key = NEW.id;
            INSERT INTO sync_outbox (sync_table, row_key) VALUES ('categories', NEW.id);
          END;
CREATE TRIGGER sync_outbox_tags_ins
          AFTER INSERT ON tags
          BEGIN
            DELETE FROM sync_outbox
              WHERE sync_table = 'tags' AND row_key = NEW.id;
            INSERT INTO sync_outbox (sync_table, row_key) VALUES ('tags', NEW.id);
          END;
CREATE TRIGGER sync_outbox_tags_upd
          AFTER UPDATE ON tags
          BEGIN
            DELETE FROM sync_outbox
              WHERE sync_table = 'tags' AND row_key = NEW.id;
            INSERT INTO sync_outbox (sync_table, row_key) VALUES ('tags', NEW.id);
          END;
CREATE TRIGGER sync_outbox_custom_field_defs_ins
          AFTER INSERT ON custom_field_defs
          BEGIN
            DELETE FROM sync_outbox
              WHERE sync_table = 'custom_field_defs' AND row_key = NEW.id;
            INSERT INTO sync_outbox (sync_table, row_key) VALUES ('custom_field_defs', NEW.id);
          END;
CREATE TRIGGER sync_outbox_custom_field_defs_upd
          AFTER UPDATE ON custom_field_defs
          BEGIN
            DELETE FROM sync_outbox
              WHERE sync_table = 'custom_field_defs' AND row_key = NEW.id;
            INSERT INTO sync_outbox (sync_table, row_key) VALUES ('custom_field_defs', NEW.id);
          END;
CREATE TRIGGER sync_outbox_cost_centers_ins
          AFTER INSERT ON cost_centers
          BEGIN
            DELETE FROM sync_outbox
              WHERE sync_table = 'cost_centers' AND row_key = NEW.id;
            INSERT INTO sync_outbox (sync_table, row_key) VALUES ('cost_centers', NEW.id);
          END;
CREATE TRIGGER sync_outbox_cost_centers_upd
          AFTER UPDATE ON cost_centers
          BEGIN
            DELETE FROM sync_outbox
              WHERE sync_table = 'cost_centers' AND row_key = NEW.id;
            INSERT INTO sync_outbox (sync_table, row_key) VALUES ('cost_centers', NEW.id);
          END;
CREATE TRIGGER sync_outbox_budgets_ins
          AFTER INSERT ON budgets
          BEGIN
            DELETE FROM sync_outbox
              WHERE sync_table = 'budgets' AND row_key = NEW.id;
            INSERT INTO sync_outbox (sync_table, row_key) VALUES ('budgets', NEW.id);
          END;
CREATE TRIGGER sync_outbox_budgets_upd
          AFTER UPDATE ON budgets
          BEGIN
            DELETE FROM sync_outbox
              WHERE sync_table = 'budgets' AND row_key = NEW.id;
            INSERT INTO sync_outbox (sync_table, row_key) VALUES ('budgets', NEW.id);
          END;
CREATE TRIGGER sync_outbox_recurring_rules_ins
          AFTER INSERT ON recurring_rules
          BEGIN
            DELETE FROM sync_outbox
              WHERE sync_table = 'recurring_rules' AND row_key = NEW.id;
            INSERT INTO sync_outbox (sync_table, row_key) VALUES ('recurring_rules', NEW.id);
          END;
CREATE TRIGGER sync_outbox_recurring_rules_upd
          AFTER UPDATE ON recurring_rules
          BEGIN
            DELETE FROM sync_outbox
              WHERE sync_table = 'recurring_rules' AND row_key = NEW.id;
            INSERT INTO sync_outbox (sync_table, row_key) VALUES ('recurring_rules', NEW.id);
          END;
CREATE TRIGGER sync_outbox_dashboard_cards_ins
          AFTER INSERT ON dashboard_cards
          BEGIN
            DELETE FROM sync_outbox
              WHERE sync_table = 'dashboard_cards' AND row_key = NEW.id;
            INSERT INTO sync_outbox (sync_table, row_key) VALUES ('dashboard_cards', NEW.id);
          END;
CREATE TRIGGER sync_outbox_dashboard_cards_upd
          AFTER UPDATE ON dashboard_cards
          BEGIN
            DELETE FROM sync_outbox
              WHERE sync_table = 'dashboard_cards' AND row_key = NEW.id;
            INSERT INTO sync_outbox (sync_table, row_key) VALUES ('dashboard_cards', NEW.id);
          END;
CREATE TRIGGER sync_outbox_transactions_ins
          AFTER INSERT ON transactions
          BEGIN
            DELETE FROM sync_outbox
              WHERE sync_table = 'transactions' AND row_key = NEW.id;
            INSERT INTO sync_outbox (sync_table, row_key) VALUES ('transactions', NEW.id);
          END;
CREATE TRIGGER sync_outbox_transactions_upd
          AFTER UPDATE ON transactions
          BEGIN
            DELETE FROM sync_outbox
              WHERE sync_table = 'transactions' AND row_key = NEW.id;
            INSERT INTO sync_outbox (sync_table, row_key) VALUES ('transactions', NEW.id);
          END;
CREATE TRIGGER sync_outbox_expense_reports_ins
          AFTER INSERT ON expense_reports
          BEGIN
            DELETE FROM sync_outbox
              WHERE sync_table = 'expense_reports' AND row_key = NEW.id;
            INSERT INTO sync_outbox (sync_table, row_key) VALUES ('expense_reports', NEW.id);
          END;
CREATE TRIGGER sync_outbox_expense_reports_upd
          AFTER UPDATE ON expense_reports
          BEGIN
            DELETE FROM sync_outbox
              WHERE sync_table = 'expense_reports' AND row_key = NEW.id;
            INSERT INTO sync_outbox (sync_table, row_key) VALUES ('expense_reports', NEW.id);
          END;
CREATE TRIGGER sync_outbox_transaction_tags_ins
          AFTER INSERT ON transaction_tags
          BEGIN
            DELETE FROM sync_outbox
              WHERE sync_table = 'transaction_tags' AND row_key = NEW.transaction_id || '|' || NEW.tag_id;
            INSERT INTO sync_outbox (sync_table, row_key) VALUES ('transaction_tags', NEW.transaction_id || '|' || NEW.tag_id);
          END;
CREATE TRIGGER sync_outbox_transaction_tags_upd
          AFTER UPDATE ON transaction_tags
          BEGIN
            DELETE FROM sync_outbox
              WHERE sync_table = 'transaction_tags' AND row_key = NEW.transaction_id || '|' || NEW.tag_id;
            INSERT INTO sync_outbox (sync_table, row_key) VALUES ('transaction_tags', NEW.transaction_id || '|' || NEW.tag_id);
          END;
CREATE TRIGGER sync_outbox_custom_field_values_ins
          AFTER INSERT ON custom_field_values
          BEGIN
            DELETE FROM sync_outbox
              WHERE sync_table = 'custom_field_values' AND row_key = NEW.transaction_id || '|' || NEW.field_id;
            INSERT INTO sync_outbox (sync_table, row_key) VALUES ('custom_field_values', NEW.transaction_id || '|' || NEW.field_id);
          END;
CREATE TRIGGER sync_outbox_custom_field_values_upd
          AFTER UPDATE ON custom_field_values
          BEGIN
            DELETE FROM sync_outbox
              WHERE sync_table = 'custom_field_values' AND row_key = NEW.transaction_id || '|' || NEW.field_id;
            INSERT INTO sync_outbox (sync_table, row_key) VALUES ('custom_field_values', NEW.transaction_id || '|' || NEW.field_id);
          END;
CREATE TRIGGER sync_outbox_expense_report_entries_ins
          AFTER INSERT ON expense_report_entries
          BEGIN
            DELETE FROM sync_outbox
              WHERE sync_table = 'expense_report_entries' AND row_key = NEW.transaction_id;
            INSERT INTO sync_outbox (sync_table, row_key) VALUES ('expense_report_entries', NEW.transaction_id);
          END;
CREATE TRIGGER sync_outbox_expense_report_entries_upd
          AFTER UPDATE ON expense_report_entries
          BEGIN
            DELETE FROM sync_outbox
              WHERE sync_table = 'expense_report_entries' AND row_key = NEW.transaction_id;
            INSERT INTO sync_outbox (sync_table, row_key) VALUES ('expense_report_entries', NEW.transaction_id);
          END;

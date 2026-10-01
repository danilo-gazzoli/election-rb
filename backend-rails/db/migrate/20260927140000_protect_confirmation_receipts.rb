# frozen_string_literal: true

class ProtectConfirmationReceipts < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      CREATE FUNCTION deny_confirmation_receipt_mutation() RETURNS trigger AS $$
      BEGIN
        RAISE EXCEPTION 'confirmation receipts are immutable';
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER confirmation_receipt_immutable
        BEFORE UPDATE OR DELETE ON confirmation_receipts
        FOR EACH ROW EXECUTE FUNCTION deny_confirmation_receipt_mutation();
    SQL
  end

  def down
    execute 'DROP TRIGGER confirmation_receipt_immutable ON confirmation_receipts'
    execute 'DROP FUNCTION deny_confirmation_receipt_mutation()'
  end
end

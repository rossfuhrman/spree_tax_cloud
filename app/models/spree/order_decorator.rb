Spree::Order.class_eval do

  has_one :tax_cloud_transaction

  register_update_hook :tax_cloud_udpate_hook
    
  def tax_cloud_udpate_hook
    if state == "address"
      lookup_tax_cloud if tax_cloud_eligible?
    end
    if state == "payment"
      capture_tax_cloud if tax_cloud_eligible?
    end
  end

  def tax_cloud_eligible?
    ship_address.try(:state_id?)
  end

  def lookup_tax_cloud
    unless tax_cloud_transaction.nil?
      tax_cloud_transaction.lookup
    else
      create_tax_cloud_transaction
      tax_cloud_transaction.lookup
      tax_cloud_adjustment
    end
  end

  def tax_cloud_adjustment
    adjustments.create do |adjustment|
      adjustment.source = self
      adjustment.originator = tax_cloud_transaction
      adjustment.label = 'Tax'
      adjustment.mandatory = true
      adjustment.eligible = true
      adjustment.amount = tax_cloud_transaction.amount
    end
  end

  def promotions_total
    adjustments.promotion.map(&:amount).sum.abs
  end

  def capture_tax_cloud
    return unless tax_cloud_transaction
    tax_cloud_transaction.capture
  end
end

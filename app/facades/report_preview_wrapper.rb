module ReportPreviewWrapper
  def wrap_in_transaction 
    ActiveRecord::Base.transaction do
      begin
        yield
      ensure
        raise ActiveRecord::Rollback
      end
    end
  end  

end

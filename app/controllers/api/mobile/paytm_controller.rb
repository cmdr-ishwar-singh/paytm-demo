require Rails.root.join("lib/paytm_helper.rb")

class Api::Mobile::PaytmController < ActionController::Base

  include PaytmHelper::EncryptionNewPG

  # MOBILE
  # post generate-checksum
  def generate_checksum
    payment_environment = (params[:payment_environment] == "production" ? :production : :staging)

    params_keys_to_accept = ["MID", "ORDER_ID", "CUST_ID", "INDUSTRY_TYPE_ID", "CHANNEL_ID", "TXN_AMOUNT",
      "WEBSITE", "CALLBACK_URL", "MOBILE_NO", "EMAIL", "THEME"]
    params_keys_to_ignore = ["USER_ID", "controller", "action", "format", "payment_environment"]

    paytmHASH = Hash.new

    paytmHASH["MID"] = ENV['mid']
    paytmHASH["ORDER_ID"] = params["ORDER_ID"]
    paytmHASH["CUST_ID"] = params["CUST_ID"]
    paytmHASH["INDUSTRY_TYPE_ID"] = ENV['industry_type_id']
    paytmHASH["CHANNEL_ID"] = ENV['channel_id']
    paytmHASH["TXN_AMOUNT"] = params["TXN_AMOUNT"]
    paytmHASH["WEBSITE"] = ENV['website']

    keys = params.keys
    keys.each do |key|
      if ! params[key].blank?
        puts "params[#{key}] : #{params[key]}"
        if !(params_keys_to_accept.include? key)
            next
        end
        paytmHASH[key] = params[key]
      end
    end

    mid = paytmHASH["MID"]
    order_id = paytmHASH["ORDER_ID"]

    Rails.logger.debug "paytmHASH: #{paytmHASH}"

    checksum_hash = PaytmHelper::ChecksumTool.new.get_checksum_hash(paytmHASH, ENV['merchant_key']).gsub("\n",'')

    # Prepare the return json.
    returnJson = Hash.new
    returnJson["CHECKSUMHASH"] =  checksum_hash
    returnJson["ORDER_ID"]     =  order_id
    returnJson["payt_STATUS"]  =  1

    Rails.logger.debug "returnJson: #{returnJson}"

    render json: returnJson
  end

  # post verify-checksum
  def verify_checksum
    params_keys_to_ignore = ["USER_ID", "controller", "action", "format"]

    paytmHASH = Hash.new

    keys = params.keys
    keys.each do |key|
      if (params_keys_to_ignore.include? key)
        next
      end

      paytmHASH[key] = params[key]
    end
    paytmHASH = PaytmHelper::ChecksumTool.new.get_checksum_verified_array(paytmHASH, ENV['merchant_key'])

    @response_value = paytmHASH.to_json.to_s.html_safe
  end
end
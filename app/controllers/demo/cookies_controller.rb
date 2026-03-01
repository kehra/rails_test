class Demo::CookiesController < ApplicationController
  before_action :authenticate_user!

  def write_demo
    cookies.signed[:teamhub_signed] = { value: "signed-value", httponly: true }
    cookies.encrypted[:teamhub_encrypted] = { value: "encrypted-value", httponly: true }
    cookies.signed[:teamhub_signed_expires] = { value: "signed-expires-value", httponly: true, expires: 1.day.from_now }
    cookies.encrypted[:teamhub_encrypted_expires] = { value: "encrypted-expires-value", httponly: true, expires: 1.day.from_now }
    cookies.permanent[:teamhub_permanent] = { value: "permanent-value", httponly: true }
    cookies.signed.permanent[:teamhub_signed_permanent] = { value: "signed-permanent-value", httponly: true }
    cookies.encrypted.permanent[:teamhub_encrypted_permanent] = { value: "encrypted-permanent-value", httponly: true }
    head :ok
  end

  def read_demo
    response.set_header("X-TeamHub-Request-Method", request.request_method)
    render json: {
      signed: cookies.signed[:teamhub_signed],
      encrypted: cookies.encrypted[:teamhub_encrypted],
      signed_expires: cookies.signed[:teamhub_signed_expires],
      encrypted_expires: cookies.encrypted[:teamhub_encrypted_expires],
      permanent: cookies.permanent[:teamhub_permanent],
      signed_permanent: cookies.signed.permanent[:teamhub_signed_permanent],
      encrypted_permanent: cookies.encrypted.permanent[:teamhub_encrypted_permanent]
    }
  end

  def clear_demo
    cookies.delete(:teamhub_signed)
    cookies.delete(:teamhub_encrypted)
    cookies.delete(:teamhub_signed_expires)
    cookies.delete(:teamhub_encrypted_expires)
    cookies.delete(:teamhub_permanent)
    cookies.delete(:teamhub_signed_permanent)
    cookies.delete(:teamhub_encrypted_permanent)
    head :ok
  end
end

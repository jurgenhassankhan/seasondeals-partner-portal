// Preparation only: no provider calls, database writes, payment, booking or email.
function "supplier/production/config_status" {
  input {}
  stack {
    var $raw_config { value = $env.NUITEE_PRODUCTION_CONFIG }
    api.lambda {
      code = """
let config;
try { config = typeof $var.raw_config === 'string' ? JSON.parse($var.raw_config) : $var.raw_config; } catch (_) { config = null; }
const flags = ['read_enabled','transactions_enabled','sales_enabled','refunds_enabled','email_enabled'];
const valid = !!config && config.schema_version === 1 && config.environment === 'production' && config.payment_method === 'ACC_CREDIT_CARD' && flags.every(k => typeof config[k] === 'boolean');
const closed = valid && flags.every(k => config[k] === false);
return { provider: 'nuitee', environment: 'production', payment_method: 'ACC_CREDIT_CARD', config_valid: valid, configured_closed: closed, release_status: 'preparation_only', production_released: false, can_read: false, can_book: false, can_pay: false, can_refund: false, can_send_email: false, can_sell: false, reason: !valid ? 'INVALID_PRODUCTION_CONFIG' : !closed ? 'UNEXPECTED_ENABLED_FLAG' : 'PRODUCTION_NOT_RELEASED' };
"""
      timeout = 5
    } as $result
  }
  response = $result
}
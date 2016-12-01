class RateController < ApplicationController
	def index
    @rates=CurrencyRate.joins("LEFT OUTER JOIN currency_rates r2 ON currency_rates.last_update=r2.last_update")
      .select("currency_rates.last_update, currency_rates.buy usd_buy, currency_rates.sell usd_sell, r2.buy eur_buy, r2.sell eur_sell")
      .where("currency_rates.from_currency=840 AND r2.from_currency=978").order(last_update: :desc)
	end
end
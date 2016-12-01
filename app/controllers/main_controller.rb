class MainController < ApplicationController
	def index
		render html: "<h1>Test page</h1>".html_safe
	end
end
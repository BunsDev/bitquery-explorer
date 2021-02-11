class Conflux::AddressController < NetworkController
  layout 'tabs'

  before_action :query_graphql, :redirect_by_type

  QUERY = BitqueryGraphql::Client.parse <<-'GRAPHQL'
   query($network: ConfluxNetwork!, $address: String!) {
              conflux(network: $network) {
                address(address: {is: $address}){
                  address 
                  annotation
                  
                  smartContract {
                    contractType
                    currency{
                      symbol
                      name
                      decimals
                      tokenType
                    }
                  }
                  balance
                }
              }
            }
  GRAPHQL

  QUERY_CURRENCIES = BitqueryGraphql::Client.parse <<-'GRAPHQL'
   query($network: ConfluxNetwork!, $address: String!) {
              conflux(network: $network) {
                address(address: {is: $address}){
                  address 
                  annotation
                  
                  smartContract {
                    contractType
                    currency{
                      symbol
                      name
                      decimals
                      tokenType
                    }
                  }
                  balance
                }
    						transfers(receiver: {is: $address}, options: {desc: "count"}){
      							currency {
                      address
                      symbol
                      name
                    }
      							count
    						}
              }
            }
  GRAPHQL

  private

  def query_graphql
    @address = params[:address]
    query = action_name == 'money_flow' ? QUERY_CURRENCIES : QUERY
    if @address.starts_with?('0x')
      result = BitqueryGraphql::Client.query(query,
                                             variables: { network: @network[:network], address: @address }).data.conflux
      @info = result.address.first
      if result.try(:transfers)
        @currencies = result.transfers.map(&:currency).sort_by do |c|
                        c.address == '-' ? 0 : 1
                      end.uniq { |x| x.address }
      end
    end
  end

  def redirect_by_type
    if sc = @info.try(:smart_contract)
      change_controller!(sc.currency ? 'conflux/token' : 'conflux/smart_contract')
    end
  end
end

module Rastreioz
  class Frete

    attr_accessor :codigo_empresa, :senha, :cep_origem, :cep_destino
    attr_accessor :diametro, :mao_propria, :aviso_recebimento, :valor_declarado
    attr_accessor :peso, :comprimento, :largura, :altura, :formato

    DEFAULT_OPTIONS = {
      :peso => 0.0,
      :comprimento => 0.0,
      :largura => 0.0,
      :altura => 0.0,
      :diametro => 0.0,
      :formato => :caixa_pacote,
      :mao_propria => false,
      :aviso_recebimento => false,
      :valor_declarado => 0.0
    }

    URL = "https://api.rastreioz.com/frete/prazo"
    FORMATS = { :caixa_pacote => 1, :rolo_prisma => 2, :envelope => 3 }
    CONDITIONS = { true => "S", false => "N" }

    def initialize(options = {})
      DEFAULT_OPTIONS.merge(options).each do |attr, value|
        self.send("#{attr}=", value)
      end
    end

    def calcular(service_types)
      servicos = {}
      begin
        url = "#{URL}?#{params_for(service_types)}"
        response = Rastreioz::Log.new.with_log {Rastreioz::Http.new.http_request(url)}
        response_body = JSON.parse(response.body)
        response_body.each do |element|
          servico = Rastreioz::Servico.new.parse(element)
          servicos[servico.tipo] = servico
        end
      rescue
        raise "Falha na Consulta ao Correio"
      end
      servicos
    end

    def self.calcular(service_types, options = {})
      self.new(options).calcular(service_types)
    end

    private

    def params_for(service_types)
      res = "sCepOrigem=#{self.cep_origem}&" +
            "sCepDestino=#{self.cep_destino}&" +
            "nVlPeso=#{self.peso}&" +
            "nVlComprimento=#{format_decimal(self.comprimento)}&" +
            "nVlLargura=#{format_decimal(self.largura)}&" +
            "nVlAltura=#{format_decimal(self.altura)}&" +
            "nVlDiametro=#{format_decimal(self.diametro)}&" +
            "nCdFormato=#{FORMATS[self.formato]}&" +
            "sCdMaoPropria=#{CONDITIONS[self.mao_propria]}&" +
            "sCdAvisoRecebimento=#{CONDITIONS[self.aviso_recebimento]}&" +
            "nVlValorDeclarado=#{format_decimal(format("%.2f" % self.valor_declarado))}&" +
            "nCdServico=#{service_codes_for(service_types)}"

      res = "#{res}&nCdEmpresa=#{self.codigo_empresa}&sDsSenha=#{self.senha}" if self.codigo_empresa && self.senha
      res
    end

    def format_decimal(value)
      value.to_s
    end

    def service_codes_for(service_types)
      service_codes = service_types.is_a?(Array) ? 
        service_types.map { |type| Rastreioz::Servico.code_from_type(type) }.join(",") :
        Rastreioz::Servico.code_from_type(service_types)
      
      puts service_codes
      service_codes
    end

  end
end

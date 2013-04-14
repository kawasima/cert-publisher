class CertSerial
  include DataMapper::Resource

  property :value, Integer, :key => true

  def self.nextval
    serial = first
    unless serial
      serial = CertSerial.new
      serial.value = 10
    end
    serial.value += 1
    serial.save!
    serial.value
  end
end

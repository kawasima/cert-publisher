CertPublisher::App.helpers do
  def control_group_for(object, name, &block)
    object = build_object(object)
    if block_given?
      content = capture_html(&block)
    end
    content = content.join("\n") if content.respond_to?(:join)
    
    class_names = ["control-group"]
    class_names << "error" unless object.errors[name].empty? 
    output = ActiveSupport::SafeBuffer.new
    output.safe_concat "<div class='#{class_names.join(" ")}'>#{content}</div>"
    block_is_template?(block) ? concat_content(output) : output
  end

  private
  def build_object(object_or_symbol)
    object_or_symbol.is_a?(Symbol) ? self.instance_variable_get("@#{object_or_symbol}") : object_or_symbol
  end
end
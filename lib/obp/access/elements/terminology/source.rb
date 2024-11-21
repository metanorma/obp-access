# HTML:
# <div class="sts-tbx-source">
#     [SOURCE:26th meeting of the CGPM (2018)
#     <sup>[</sup>
#     <a class="sts-xref" href="#iso:std:iso:34000:ed-1:v1:en:ref:10" title="
#         [10] CGPM22 Conférence Générale des Poids et Mesures / General Conference on Weights and Measures. Meeting 26,
#         General Conference on Weights and Measures. 26th meeting of the CGPM. Paris: Bureau International des Poids et
#         Mesures. November 16, 2018. Available from: https://www.bipm.org/en/committees/cg/cgpm/26-2018.">
#         <sup>10</sup>
#     </a>
#     <sup>]</sup>
#     , Resolution 2, modified – Note 1 to entry has been expanded upon for clarity.]
# </div>
# STS:
# <tbx:source>
#   26th meeting of the CGPM (2018)
#   <sup>[</sup><xref ref-type="bibr" rid="ref_10"><sup>10</sup></xref><sup>]</sup>,
#   Resolution 2, modified – Note 1 to entry has been expanded upon for clarity.
# </tbx:source>
module Obp
  module Access
    class Rendered
      class Elements
        class Terminology
          class Source < Base
            def self.classes
              %w[sts-tbx-source]
            end

            def content
              Nokogiri::XML::Builder.new do |xml|
                xml.send(:"tbx:source") do
                  node.children.each do |child|
                    if child.classes == ["sts-xref"]
                      render_ref(xml, child)
                    else
                      render_text(xml, child)
                    end
                  end
                end
              end
            end

            private

            def render_ref(xml, child)
              rid = child.attr("href").split(":").last
              xml.xref("ref-type": "bibr", rid: "ref_#{rid}") { xml << child.inner_html }
            end

            def render_text(xml, child)
              content = child.to_s.strip.gsub(/^\[SOURCE:|\]$/, "")
              xml << content
            end
          end
        end
      end
    end
  end
end

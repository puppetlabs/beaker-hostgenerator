require 'beaker-hostgenerator/parser'

module BeakerHostGenerator
  describe Parser do
    include BeakerHostGenerator::Parser

    describe 'prepare' do
      it 'Supports URL-encoded input' do
        expect( prepare('centos6-64m%7Bfoo=bar-baz,this=that%7D-32a%5Bfoo=bar,baz%3Bthis=that%5D') ).
          to eq('centos6-64m{foo=bar-baz,this=that}-32a[foo=bar,baz;this=that]')
      end
    end

    describe 'parse_node_info_token' do

      it 'Raises InvalidNodeSpecError for invalid tokens.' do
        expect { parse_node_info_token("64compile_master") }.
          to raise_error(BeakerHostGenerator::Exceptions::InvalidNodeSpecError)
      end

      it 'Supports no roles in the spec.' do
        expect( parse_node_info_token("64") ).
          to eq({
                  "roles" => "",
                  "arbitrary_roles" => [],
                  "bits" => "64",
                  "host_lists" => {},
                  "host_settings" => {}
                })
      end

      context 'When specifying architecture bits' do

        it 'Supports uppercase alphanumeric architecture bits' do
          expect( parse_node_info_token("SPARC") ).
            to eq({
                    "roles" => "",
                    "arbitrary_roles" => [],
                    "bits" => "SPARC",
                    "host_lists" => {},
                    "host_settings" => {}
                  })

          expect( parse_node_info_token("POWER6") ).
            to eq({
                    "roles" => "",
                    "arbitrary_roles" => [],
                    "bits" => "POWER6",
                    "host_lists" => {},
                    "host_settings" => {}
                  })

          expect( parse_node_info_token("S390X") ).
            to eq({
                    "roles" => "",
                    "arbitrary_roles" => [],
                    "bits" => "S390X",
                    "host_lists" => {},
                    "host_settings" => {}
                  })

        end

        it 'Trailing lowercase characters are parsed as roles' do
          expect( parse_node_info_token("S390Xm") ).
            to eq({
                    "roles" => "m",
                    "arbitrary_roles" => [],
                    "bits" => "S390X",
                    "host_lists" => {},
                    "host_settings" => {}
                  })

          expect( parse_node_info_token("S390Xcustom.m") ).
            to eq({
                    "roles" => "m",
                    "arbitrary_roles" => ["custom"],
                    "bits" => "S390X",
                    "host_lists" => {},
                    "host_settings" => {}
                  })
        end

        it 'Rejects lowercase characters that are not at the end' do
          expect { parse_node_info_token("AbC3") }.
            to raise_error(BeakerHostGenerator::Exceptions::InvalidNodeSpecError)

          expect { parse_node_info_token("aBC3") }.
            to raise_error(BeakerHostGenerator::Exceptions::InvalidNodeSpecError)
        end
      end

      it 'Supports the use of arbitrary roles.' do
        expect( parse_node_info_token("64compile_master,ca,blah.mad") ).
          to eq({
                  "roles" => "mad",
                  "arbitrary_roles" => ["compile_master", "ca", "blah"],
                  "bits" => "64",
                  "host_lists" => {},
                  "host_settings" => {}
                })
      end

      context 'When using arbitrary roles' do

        it 'Fails without a role-type delimiter (a period)' do
          expect { parse_node_info_token("64compile_master,ca,blah") }.
            to raise_error(BeakerHostGenerator::Exceptions::InvalidNodeSpecError)
        end

        it 'It supports no static roles.' do
          expect( parse_node_info_token("64compile_master,ca,blah.") ).
            to eq({
                    "roles" => "",
                    "arbitrary_roles" => ["compile_master", "ca", "blah"],
                    "bits" => "64",
                    "host_lists" => {},
                    "host_settings" => {}
                  })
        end
      end

      context 'When using arbitrary host settings' do
        it 'Supports arbitrary whitespace in values' do
          expect( parse_node_info_token("64{k1=value 1,k2=v2,k3=  v3  }") ).
            to eq({
                    "roles" => "",
                    "arbitrary_roles" => [],
                    "bits" => "64",
                    "host_lists" => {},
                    "host_settings" => {
                      "k1" => "value 1",
                      "k2" => "v2",
                      "k3" => "  v3  "
                    }
                  })
        end

        it 'Raises InvalidNodeSpecError for malformed key-value pairs' do
          expect { parse_node_info_token("64{foo=bar=baz}") }.
            to raise_error(BeakerHostGenerator::Exceptions::InvalidNodeSpecError)

          expect { parse_node_info_token("64{foo=}") }.
            to raise_error(BeakerHostGenerator::Exceptions::InvalidNodeSpecError)

          expect { parse_node_info_token("64{=bar}") }.
            to raise_error(BeakerHostGenerator::Exceptions::InvalidNodeSpecError)

          expect { parse_node_info_token("64{=}") }.
            to raise_error(BeakerHostGenerator::Exceptions::InvalidNodeSpecError)
        end

        context 'When using arbitrary host lists' do
          it 'Supports arbitrary whitespace in lists' do
            expect( parse_node_info_token("64[k1=value 1,value 2;k2=v2,v3,v4,v5;k3=  v6  ]") ).
              to eq({
                      "roles" => "",
                      "arbitrary_roles" => [],
                      "bits" => "64",
                      "host_settings" => {},
                      "host_lists" => {
                        "k1" => ["value 1", "value 2"],
                        "k2" => ["v2", "v3", "v4", "v5"],
                        "k3" => ["  v6  "]
                      }
                    })
          end

          it 'Raises InvalidNodeSpecError for malformed key-list pairs' do
            expect { parse_node_info_token("64[foo=bar=baz]") }.
              to raise_error(BeakerHostGenerator::Exceptions::InvalidNodeSpecError)

            expect { parse_node_info_token("64[foo=bar,barbar=baz]") }.
              to raise_error(BeakerHostGenerator::Exceptions::InvalidNodeSpecError)

            expect { parse_node_info_token("64[foo=]") }.
              to raise_error(BeakerHostGenerator::Exceptions::InvalidNodeSpecError)

            expect { parse_node_info_token("64[=bar,foo]") }.
              to raise_error(BeakerHostGenerator::Exceptions::InvalidNodeSpecError)

            expect { parse_node_info_token("64[=]") }.
              to raise_error(BeakerHostGenerator::Exceptions::InvalidNodeSpecError)
          end
        end
      end
    end
  end
end

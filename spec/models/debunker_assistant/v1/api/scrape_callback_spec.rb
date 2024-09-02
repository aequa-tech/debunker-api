# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::DebunkerAssistant::V1::Api::ScrapeCallback, type: :model do
  let!(:user) { create(:user, :confirmed) }
  let!(:key_pair) { ApiKey.generate_key_pair }
  let!(:api_key) do
    create(:api_key, access_token: key_pair[:access_token], secret_token: key_pair[:secret_token], user:)
  end
  let(:token_value) { api_key.available_tokens.first.value }

  let(:token) { Token.find_by(value: token_value) }
  let(:support_response_object) { JSON.parse(token.support_response_object) }
  let(:valid_payload) do
    {
      url: 'https://www.google.com',
      analysis_types: {
        evaluation: {
          callback_url: 'https://example.com/evaluation'
        },
        explanations: {
          callback_url: 'https://example.com/explanations',
          explanation_types: %w[explanationAffective explanationDanger explanationNetworkAnalysis]
        }
      },
      content_language: 'en',
      retry: true,
      max_retries: 3,
      timeout: 10,
      max_chars: 1000
    }
  end

  evaluation_structure = {
    'analysis_id' => '',
    'informalStyle' => {
      'overallScore' => {
        'title' => '',
        'content' => ''
      },
      'disaggregated' => {
        'secondPerson' => {
          'title' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          },
          'content' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          }
        },
        'personalStyle' => {
          'title' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          },
          'content' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          }
        },
        'intensifiers' => {
          'title' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          },
          'content' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          }
        },
        'shortenedForms' => {
          'title' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          },
          'content' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          }
        },
        'modals' => {
          'title' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          },
          'content' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          }
        },
        'interrogatives' => {
          'title' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          },
          'content' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          }
        },
        'uppercaseWords' => {
          'title' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          },
          'content' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          }
        },
        'repeatedLetters' => {
          'title' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          },
          'content' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          }
        },
        'aggressivePunctuation' => {
          'title' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          },
          'content' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          }
        },
        'uncommonPunctuation' => {
          'title' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          },
          'content' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          }
        },
        'emoji' => {
          'title' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          },
          'content' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          }
        }
      }
    },
    'readability' => {
      'overallScore' => {
        'title' => '',
        'content' => ''
      },
      'disaggregated' => {
        'fleshReadingEase' => {
          'title' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          },
          'content' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          }
        }
      }
    },
    'clickBait' => {
      'overallScore' => {
        'title' => '',
        'content' => ''
      },
      'disaggregated' => {
        'misleadingHeadline' => {
          'title' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          },
          'content' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          }
        }
      }
    },
    'affectiveStyle' => {
      'overallScore' => {
        'title' => '',
        'content' => ''
      },
      'disaggregated' => {
        'positiveSentiment' => {
          'title' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          },
          'content' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          }
        },
        'negativeSentiment' => {
          'title' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          },
          'content' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          }
        },
        'joy' => {
          'title' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          },
          'content' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          }
        },
        'sadness' => {
          'title' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          },
          'content' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          }
        },
        'fear' => {
          'title' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          },
          'content' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          }
        },
        'anger' => {
          'title' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          },
          'content' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          }
        }
      }
    },
    'dangerousStyle' => {
      'overallScore' => {
        'title' => '',
        'content' => ''
      },
      'disaggregated' => {
        'irony' => {
          'title' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          },
          'content' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          }
        },
        'flame' => {
          'title' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          },
          'content' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          }
        },
        'stereotype' => {
          'title' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          },
          'content' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          }
        }
      }
    },
    'untrustability' => {
      'overallScore' => '',
      'disaggregated' => {
        'labelPropagation' => {
          'values' => {
            'absolute' => '',
            'local' => '',
            'global' => ''
          }
        }
      }
    },
    'status' => ''
  }

  explanation_affective_structure = {
    'negative' => {
      'token' => '',
      'probability' => ''
    },
    'positive' => {
      'token' => '',
      'probability' => ''
    },
    'anger' => {
      'token' => '',
      'probability' => ''
    },
    'sadness' => {
      'token' => '',
      'probability' => ''
    },
    'joy' => {
      'token' => '',
      'probability' => ''
    },
    'fear' => {
      'token' => '',
      'probability' => ''
    }
  }

  explanation_danger_structure = {
    'flame' => {
      'token' => '',
      'probability' => ''
    },
    'stereotype' => {
      'token' => '',
      'probability' => ''
    },
    'irony' => {
      'token' => '',
      'probability' => ''
    }
  }

  context 'when happy path' do
    let(:cassettes) do
      [
        { name: 'scrape_success' },
        { name: 'evaluation_success' },
        { name: 'explanation_affective_success' },
        { name: 'explanation_danger_success' },
        { name: 'explanation_network_success' }
      ]
    end

    context 'when evaluation' do
      it 'payload is correct' do
        VCR.use_cassettes cassettes do
          ::DebunkerAssistant::V1::Api::ScrapePerform.new(valid_payload.to_json, token_value).scrape
        end

        payload = described_class.new(valid_payload.to_json, token_value).check_callback_payload(:evaluation)
        expect(payload.is_a?(Hash)).to be_truthy
        expect(payload.keys).to match_array(%i[token_id url analysisType data])
        expect(payload[:token_id]).to eq(token.value)
        expect(payload[:url]).to eq(valid_payload[:url])
        expect(payload[:analysisType]).to eq('evaluation')
        expect(payload[:data].is_a?(Hash)).to be_truthy
      end

      it 'evaluation data corresponds to openapi schema' do
        VCR.use_cassettes cassettes do
          ::DebunkerAssistant::V1::Api::ScrapePerform.new(valid_payload.to_json, token_value).scrape
        end

        payload = described_class.new(valid_payload.to_json, token_value).check_callback_payload(:evaluation)
        puts "\n\n###### EVALUTATION PAYLOAD ######"
        expect(response_expetation(payload[:data].deep_stringify_keys, evaluation_structure)).to be_truthy
      end
    end

    context 'when explanations' do
      it 'payload is correct' do
        VCR.use_cassettes cassettes do
          ::DebunkerAssistant::V1::Api::ScrapePerform.new(valid_payload.to_json, token_value).scrape
        end

        payload = described_class.new(valid_payload.to_json, token_value).check_callback_payload(:explanations)
        expect(payload.is_a?(Hash)).to be_truthy
        expect(payload.keys).to match_array(%i[token_id url analysisType data])
        expect(payload[:token_id]).to eq(token.value)
        expect(payload[:url]).to eq(valid_payload[:url])
        expect(payload[:analysisType]).to eq('explanations')
        expect(payload[:data].is_a?(Array)).to be_truthy
      end

      it 'explanations data corresponds to openapi schema' do
        VCR.use_cassettes cassettes do
          ::DebunkerAssistant::V1::Api::ScrapePerform.new(valid_payload.to_json, token_value).scrape
        end

        payload = described_class.new(valid_payload.to_json, token_value).check_callback_payload(:explanations)
        payload[:data].each do |explanation|
          case explanation[:explanationDim]
          when 'explanationAffective'
            expect(explanation.keys).to match_array(%i[explanationDim data status])
            puts "\n\n###### EXPLANATION AFFECTIVE PAYLOAD ######"
            expect(response_expetation(explanation[:data].deep_stringify_keys,
                                       explanation_affective_structure)).to be_truthy
          when 'explanationDanger'
            expect(explanation.keys).to match_array(%i[explanationDim data status])
            puts "\n\n###### EXPLANATION DANGER PAYLOAD ######"
            expect(response_expetation(explanation[:data].deep_stringify_keys,
                                       explanation_danger_structure)).to be_truthy
          when 'explanationNetworkAnalysis'
            expect(explanation.keys).to match_array(%i[explanationDim message status])
          end
        end
      end
    end
  end

  context 'when scrape fails' do
    let(:cassettes) do
      [
        { name: 'scrape_failure' }
      ]
    end

    context 'when evaluation' do
      it 'payload is correct' do
        VCR.use_cassettes cassettes do
          ::DebunkerAssistant::V1::Api::ScrapePerform.new(valid_payload.to_json, token_value).scrape
        end

        payload = described_class.new(valid_payload.to_json, token_value).check_callback_payload(:evaluation)
        expect(payload.is_a?(Hash)).to be_truthy
        expect(payload.keys).to match_array(%i[token_id url analysisType data])
        expect(payload[:token_id]).to eq(token.value)
        expect(payload[:url]).to eq(valid_payload[:url])
        expect(payload[:analysisType]).to eq('evaluation')
        expect(payload[:data].is_a?(Hash)).to be_truthy
      end

      it 'evaluation is message with status' do
        VCR.use_cassettes cassettes do
          ::DebunkerAssistant::V1::Api::ScrapePerform.new(valid_payload.to_json, token_value).scrape
        end

        payload = described_class.new(valid_payload.to_json, token_value).check_callback_payload(:evaluation)
        expect(payload[:data].keys).to match_array(%i[message status])
        expect(payload[:data][:message]).to be_present
        expect(payload[:data][:status]).not_to eq 200
      end
    end

    context 'when explanations' do
      it 'payload is correct' do
        VCR.use_cassettes cassettes do
          ::DebunkerAssistant::V1::Api::ScrapePerform.new(valid_payload.to_json, token_value).scrape
        end

        payload = described_class.new(valid_payload.to_json, token_value).check_callback_payload(:explanations)
        expect(payload.is_a?(Hash)).to be_truthy
        expect(payload.keys).to match_array(%i[token_id url analysisType data])
        expect(payload[:token_id]).to eq(token.value)
        expect(payload[:url]).to eq(valid_payload[:url])
        expect(payload[:analysisType]).to eq('explanations')
        expect(payload[:data].is_a?(Array)).to be_truthy
      end

      it 'explanations is message with status' do
        VCR.use_cassettes cassettes do
          ::DebunkerAssistant::V1::Api::ScrapePerform.new(valid_payload.to_json, token_value).scrape
        end

        payload = described_class.new(valid_payload.to_json, token_value).check_callback_payload(:explanations)
        payload[:data].each do |explanation|
          expect(explanation.keys).to match_array(%i[explanationDim message status])
          expect(explanation[:message]).to be_present
          expect(explanation[:status]).not_to eq 200
        end
      end
    end
  end

  context 'when evaluation fails' do
    let(:cassettes) do
      [
        { name: 'scrape_failure' },
        { name: 'evaluation_failure' }
      ]
    end

    context 'when evaluation' do
      it 'payload is correct' do
        VCR.use_cassettes cassettes do
          ::DebunkerAssistant::V1::Api::ScrapePerform.new(valid_payload.to_json, token_value).scrape
        end

        payload = described_class.new(valid_payload.to_json, token_value).check_callback_payload(:evaluation)
        expect(payload.is_a?(Hash)).to be_truthy
        expect(payload.keys).to match_array(%i[token_id url analysisType data])
        expect(payload[:token_id]).to eq(token.value)
        expect(payload[:url]).to eq(valid_payload[:url])
        expect(payload[:analysisType]).to eq('evaluation')
        expect(payload[:data].is_a?(Hash)).to be_truthy
      end

      it 'evaluation is message with status' do
        VCR.use_cassettes cassettes do
          ::DebunkerAssistant::V1::Api::ScrapePerform.new(valid_payload.to_json, token_value).scrape
        end

        payload = described_class.new(valid_payload.to_json, token_value).check_callback_payload(:evaluation)
        expect(payload[:data].keys).to match_array(%i[message status])
        expect(payload[:data][:message]).to be_present
        expect(payload[:data][:status]).not_to eq 200
      end
    end

    context 'when explanations' do
      it 'payload is correct' do
        VCR.use_cassettes cassettes do
          ::DebunkerAssistant::V1::Api::ScrapePerform.new(valid_payload.to_json, token_value).scrape
        end

        payload = described_class.new(valid_payload.to_json, token_value).check_callback_payload(:explanations)
        expect(payload.is_a?(Hash)).to be_truthy
        expect(payload.keys).to match_array(%i[token_id url analysisType data])
        expect(payload[:token_id]).to eq(token.value)
        expect(payload[:url]).to eq(valid_payload[:url])
        expect(payload[:analysisType]).to eq('explanations')
        expect(payload[:data].is_a?(Array)).to be_truthy
      end

      it 'explanations is message with status' do
        VCR.use_cassettes cassettes do
          ::DebunkerAssistant::V1::Api::ScrapePerform.new(valid_payload.to_json, token_value).scrape
        end

        payload = described_class.new(valid_payload.to_json, token_value).check_callback_payload(:explanations)
        payload[:data].each do |explanation|
          expect(explanation.keys).to match_array(%i[explanationDim message status])
          expect(explanation[:message]).to be_present
          expect(explanation[:status]).not_to eq 200
        end
      end
    end
  end

  context 'when explanations affective fails' do
    let(:cassettes) do
      [
        { name: 'scrape_success' },
        { name: 'evaluation_success' },
        { name: 'explanation_affective_failure' },
        { name: 'explanation_danger_success' },
        { name: 'explanation_network_success' }
      ]
    end

    context 'when evaluation' do
      it 'payload is correct' do
        VCR.use_cassettes cassettes do
          ::DebunkerAssistant::V1::Api::ScrapePerform.new(valid_payload.to_json, token_value).scrape
        end

        payload = described_class.new(valid_payload.to_json, token_value).check_callback_payload(:evaluation)
        expect(payload.is_a?(Hash)).to be_truthy
        expect(payload.keys).to match_array(%i[token_id url analysisType data])
        expect(payload[:token_id]).to eq(token.value)
        expect(payload[:url]).to eq(valid_payload[:url])
        expect(payload[:analysisType]).to eq('evaluation')
        expect(payload[:data].is_a?(Hash)).to be_truthy
      end

      # OpenAPI schema is tested in happy path
    end

    context 'when explanations' do
      it 'payload is correct' do
        VCR.use_cassettes cassettes do
          ::DebunkerAssistant::V1::Api::ScrapePerform.new(valid_payload.to_json, token_value).scrape
        end

        payload = described_class.new(valid_payload.to_json, token_value).check_callback_payload(:explanations)
        expect(payload.is_a?(Hash)).to be_truthy
        expect(payload.keys).to match_array(%i[token_id url analysisType data])
        expect(payload[:token_id]).to eq(token.value)
        expect(payload[:url]).to eq(valid_payload[:url])
        expect(payload[:analysisType]).to eq('explanations')
        expect(payload[:data].is_a?(Array)).to be_truthy
      end

      it 'explanations is message with status' do
        VCR.use_cassettes cassettes do
          ::DebunkerAssistant::V1::Api::ScrapePerform.new(valid_payload.to_json, token_value).scrape
        end

        payload = described_class.new(valid_payload.to_json, token_value).check_callback_payload(:explanations)
        payload[:data].each do |explanation|
          case explanation[:explanationDim]
          when 'explanationAffective'
            expect(explanation.keys).to match_array(%i[explanationDim message status])
            expect(explanation[:message]).to be_present
            expect(explanation[:status]).not_to eq 200
          when 'explanationDanger'
            expect(explanation.keys).to match_array(%i[explanationDim data status])
            expect(explanation[:data].is_a?(Hash)).to be_truthy
            expect(explanation[:status]).to eq 200
          when 'explanationNetworkAnalysis'
            expect(explanation.keys).to match_array(%i[explanationDim message status])
          end
        end
      end
    end
  end

  context 'when explanations danger fails' do
    let(:cassettes) do
      [
        { name: 'scrape_success' },
        { name: 'evaluation_success' },
        { name: 'explanation_affective_success' },
        { name: 'explanation_danger_failure' },
        { name: 'explanation_network_success' }
      ]
    end

    context 'when evaluation' do
      it 'payload is correct' do
        VCR.use_cassettes cassettes do
          ::DebunkerAssistant::V1::Api::ScrapePerform.new(valid_payload.to_json, token_value).scrape
        end

        payload = described_class.new(valid_payload.to_json, token_value).check_callback_payload(:evaluation)
        expect(payload.is_a?(Hash)).to be_truthy
        expect(payload.keys).to match_array(%i[token_id url analysisType data])
        expect(payload[:token_id]).to eq(token.value)
        expect(payload[:url]).to eq(valid_payload[:url])
        expect(payload[:analysisType]).to eq('evaluation')
        expect(payload[:data].is_a?(Hash)).to be_truthy
      end

      # OpenAPI schema is tested in happy path
    end

    context 'when explanations' do
      it 'payload is correct' do
        VCR.use_cassettes cassettes do
          ::DebunkerAssistant::V1::Api::ScrapePerform.new(valid_payload.to_json, token_value).scrape
        end

        payload = described_class.new(valid_payload.to_json, token_value).check_callback_payload(:explanations)
        expect(payload.is_a?(Hash)).to be_truthy
        expect(payload.keys).to match_array(%i[token_id url analysisType data])
        expect(payload[:token_id]).to eq(token.value)
        expect(payload[:url]).to eq(valid_payload[:url])
        expect(payload[:analysisType]).to eq('explanations')
        expect(payload[:data].is_a?(Array)).to be_truthy
      end

      it 'explanations is message with status' do
        VCR.use_cassettes cassettes do
          ::DebunkerAssistant::V1::Api::ScrapePerform.new(valid_payload.to_json, token_value).scrape
        end

        payload = described_class.new(valid_payload.to_json, token_value).check_callback_payload(:explanations)
        payload[:data].each do |explanation|
          case explanation[:explanationDim]
          when 'explanationAffective'
            expect(explanation.keys).to match_array(%i[explanationDim data status])
            expect(explanation[:data].is_a?(Hash)).to be_truthy
            expect(explanation[:status]).to eq 200
          when 'explanationDanger'
            expect(explanation.keys).to match_array(%i[explanationDim message status])
            expect(explanation[:message]).to be_present
            expect(explanation[:status]).not_to eq 200
          when 'explanationNetworkAnalysis'
            expect(explanation.keys).to match_array(%i[explanationDim message status])
          end
        end
      end
    end
  end
end

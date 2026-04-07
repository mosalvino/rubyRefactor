require_relative '../refactor_me'

RSpec.describe Dino do
  let(:herbivore)  { Dino.new(name: 'DinoA', category: 'herbivore', period: 'Cretaceous', diet: 'plants', age: 100) }
  let(:carnivore)  { Dino.new(name: 'DinoB', category: 'carnivore', period: 'Jurassic',   diet: 'meat',   age: 80)  }
  let(:wrong_diet) { Dino.new(name: 'DinoC', category: 'herbivore', period: 'Triassic',   diet: 'meat',   age: 50)  }
  let(:dead_dino)  { Dino.new(name: 'DinoD', category: 'herbivore', period: 'Triassic',   diet: 'plants', age: 200) }

  describe '#process!' do
    context 'correct diet' do
      it 'marks herbivore alive when age leaves positive health' do
        carnivore.process!
        expect(carnivore.health).to eq(20)
        expect(carnivore.comment).to eq('Alive')
      end

      it 'marks herbivore dead when age reaches max health' do
        herbivore.process!
        expect(herbivore.health).to eq(0)
        expect(herbivore.comment).to eq('Dead')
      end
    end

    context 'wrong diet' do
      it 'halves base health when diet does not match category' do
        wrong_diet.process!
        expect(wrong_diet.health).to eq(25)   # (100 - 50) / 2
        expect(wrong_diet.comment).to eq('Alive')
      end
    end

    context 'age boundary' do
      it 'is Dead when age exactly equals MAX_HEALTH' do
        dino = Dino.new(name: 'Edge', category: 'carnivore', diet: 'meat', age: 100)
        dino.process!
        expect(dino.health).to eq(0)
        expect(dino.comment).to eq('Dead')
      end

      it 'is Dead when age exceeds MAX_HEALTH' do
        dead_dino.process!
        expect(dead_dino.health).to eq(0)
        expect(dead_dino.comment).to eq('Dead')
        expect(dead_dino.age_metrics).to eq(0)
      end
    end

    context 'age_metrics' do
      it 'sets age_metrics to half age when alive' do
        carnivore.process!
        expect(carnivore.age_metrics).to eq(40)  # 80 / 2
      end

      it 'sets age_metrics to 0 when dead' do
        herbivore.process!
        expect(herbivore.age_metrics).to eq(0)
      end

      it 'sets age_metrics to 0 when alive but age is 1' do
        dino = Dino.new(name: 'Baby', category: 'carnivore', diet: 'meat', age: 1)
        dino.process!
        expect(dino.age_metrics).to eq(0)
      end
    end

    context 'edge cases' do
      it 'handles nil age as Dead' do
        dino = Dino.new(name: 'Test', category: 'herbivore', diet: 'plants', age: nil)
        dino.process!
        expect(dino.health).to eq(0)
        expect(dino.comment).to eq('Dead')
      end

      it 'treats unknown category as Dead' do
        dino = Dino.new(name: 'Mystery', category: 'unknown', diet: 'plants', age: 50)
        dino.process!
        expect(dino.health).to eq(0)
        expect(dino.comment).to eq('Dead')
      end

      it 'accepts string-keyed attribute hashes' do
        dino = Dino.new('name' => 'StrKey', 'category' => 'carnivore', 'diet' => 'meat', 'age' => 50)
        dino.process!
        expect(dino.health).to eq(50)
        expect(dino.comment).to eq('Alive')
      end
    end

    describe '#to_h' do
      it 'includes all expected keys after processing' do
        carnivore.process!
        result = carnivore.to_h
        expect(result.keys).to match_array(%i[name category period diet age health comment age_metrics])
      end

      it 'reflects processed values' do
        carnivore.process!
        expect(carnivore.to_h[:health]).to eq(20)
        expect(carnivore.to_h[:comment]).to eq('Alive')
      end
    end
  end
end

RSpec.describe DinoManager do
  let(:data) do
    [
      { name: 'DinoA', category: 'herbivore', period: 'Cretaceous', diet: 'plants', age: 100 },
      { name: 'DinoB', category: 'carnivore', period: 'Jurassic',   diet: 'meat',   age: 80  },
      { name: 'DinoC', category: 'herbivore', period: 'Triassic',   diet: 'meat',   age: 50  }
    ]
  end

  describe '#result' do
    it 'returns dinos and summary keys' do
      result = DinoManager.new(data).result
      expect(result).to include(:dinos, :summary)
    end

    it 'returns correct summary counts' do
      result = DinoManager.new(data).result
      expect(result[:summary]).to eq({ 'herbivore' => 2, 'carnivore' => 1 })
    end

    it 'processes all dinos' do
      result = DinoManager.new(data).result
      expect(result[:dinos].size).to eq(3)
      expect(result[:dinos][0][:comment]).to eq('Dead')
      expect(result[:dinos][1][:comment]).to eq('Alive')
      expect(result[:dinos][2][:health]).to eq(25)
    end

    context 'empty input' do
      it 'returns empty dinos and empty summary' do
        result = DinoManager.new([]).result
        expect(result[:dinos]).to eq([])
        expect(result[:summary]).to eq({})
      end
    end

    context 'all dead' do
      it 'marks every dino Dead and still summarises categories' do
        dead_data = [
          { name: 'Dead1', category: 'herbivore', period: 'Triassic', diet: 'plants', age: 200 },
          { name: 'Dead2', category: 'carnivore', period: 'Jurassic', diet: 'meat',   age: 150 }
        ]
        result = DinoManager.new(dead_data).result
        expect(result[:dinos].all? { |d| d[:health] == 0 }).to be true
        expect(result[:dinos].all? { |d| d[:comment] == 'Dead' }).to be true
        expect(result[:summary]).to eq({ 'herbivore' => 1, 'carnivore' => 1 })
      end
    end

    context 'mixed valid and unknown categories' do
      it 'handles good and bad categories in the same batch' do
        mixed = [
          { name: 'Good', category: 'carnivore', diet: 'meat',   age: 50 },
          { name: 'Bad',  category: 'unknown',   diet: 'plants', age: 50 }
        ]
        result = DinoManager.new(mixed).result
        good = result[:dinos].find { |d| d[:name] == 'Good' }
        bad  = result[:dinos].find { |d| d[:name] == 'Bad'  }

        expect(good[:health]).to eq(50)
        expect(good[:comment]).to eq('Alive')
        expect(bad[:health]).to eq(0)
        expect(bad[:comment]).to eq('Dead')
      end
    end

    context 'idempotency' do
      it 'produces the same result when called twice on the same manager' do
        manager = DinoManager.new(data)
        first  = manager.result
        second = manager.result
        expect(first[:dinos].map { |d| d[:health] }).to eq(second[:dinos].map { |d| d[:health] })
      end
    end
  end
end
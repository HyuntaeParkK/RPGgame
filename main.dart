import 'dart:io';
import 'dart:math';

// 추상 클래스 Entity
abstract class Entity {
  String name;
  int health;
  int attackPower;
  int defense;

  Entity(this.name, this.health, this.attackPower, this.defense);

  void showStatus();
}

// Character 클래스
class Character extends Entity {
  bool itemUsed = false;

  Character(String name, int health, int attack, int defense)
      : super(name, health, attack, defense);

  @override
  void showStatus() {
    print('[캐릭터 상태] $name | 체력: $health | 공격력: $attackPower | 방어력: $defense');
  }

  void attackMonster(Monster m) {
    int damage = max(0, attackPower - m.defense);
    m.health -= damage;
    print('$name이(가) $damage의 피해를 입혔습니다.');
  }

  void defend(int incomingDamage) {
    health += incomingDamage;
    print('방어 성공! $incomingDamage 만큼 체력을 회복했습니다. 현재 체력: $health');
  }

  void useItem() {    // 아이템을 이용해서 해당 턴에 공격력 2배 적용
    if (itemUsed) {
      print('이미 아이템을 사용했습니다.');
      return;
    }
    itemUsed = true;
    attackPower *= 2;
    print('아이템 사용! 한 턴 동안 공격력이 두 배가 됩니다. 현재 공격력: \$attackPower');
  }
}

// Monster 클래스
class Monster extends Entity {
  Monster(String name, int health, int maxAttack)
      : super(name, health, Random().nextInt(maxAttack + 1), 0) {
    if (attackPower < defense) attackPower = defense;
  }

  @override
  void showStatus() {
    print('[몬스터 상태] $name | 체력: $health | 공격력: $attackPower | 방어력: $defense');
  }

  void attackCharacter(Character c) {
    int damage = max(0, attackPower - c.defense);
    c.health -= damage;
    print('$name이(가) $damage의 피해를 입혔습니다.');
  }

  void increaseDefense() {    // 3번의 턴이 지났을 때 이 함수를 불러서 몬스터의 방어력을 2만큼 올려주는 함수
    defense += 2;
    print('$name의 방어력이 증가했습니다! 현재 방어력: $defense');
  }
}

// Game 클래스
class Game {
  late Character character;
  List<Monster> monsters = [];
  final Random rand = Random();

  void startGame() {
    _loadCharacter();
    _bonusHealth();
    _loadMonsters();


    bool cont = true;
    while (cont && character.health > 0 && monsters.isNotEmpty) {
      cont = _battle();
    }

    if (character.health <= 0) {
      print('체력이 0이 되어 패배했습니다.');
      _saveResult(false);
    } else if (monsters.isEmpty) {
      print('모든 몬스터를 처치하여 승리했습니다!');
      _saveResult(true);
    } else {
      print('게임을 종료합니다.');
      _saveResult(false);
    }
  }

bool _battle() {
  Monster monster = _getRandomMonster();
  int defenseCount = 0;
  print('\n${character.name}의 턴');
  monster.showStatus();
  character.showStatus();

  while (character.health > 0 && monster.health > 0) {
    // 1. 캐릭터 턴
    stdout.write('행동 선택 (1: 공격, 2: 방어, 3: 아이템): ');
    String? input = stdin.readLineSync();
    switch (input) {
      case '1':
        character.attackMonster(monster);
        break;
      case '2':
        print('${character.name}가 방어를 선택했습니다.');
        break;
      case '3':
        character.useItem();
        break;
      default:
        print('올바른 선택이 아닙니다.');
        continue;
    }

    // 몬스터가 이미 죽었으면 턴 종료
    if (monster.health <= 0) break;
    print('\n${monster.name}의 턴');
    print('${monster.name} - 체력: ${monster.health}, 공격력: ${monster.attackPower}, 방어력: ${monster.defense}');
    // 2. 몬스터 턴
    monster.attackCharacter(character);


    // 캐릭터가 죽었으면 턴 종료
    if (character.health <= 0) break;

    // 상태 출력
    monster.showStatus();
    character.showStatus();

    // 다음 턴
    defenseCount++;
    if (defenseCount == 3) {
      monster.increaseDefense();
      defenseCount = 0;
    }
  }

  if (monster.health <= 0) {
    print('${monster.name} 처치!');
    monsters.remove(monster);
    stdout.write('다음 몬스터와 대결하시겠습니까? (y/n): ');
    String? yn = stdin.readLineSync();
    return yn?.toLowerCase() == 'y';
  }
  return false;
}


  Monster _getRandomMonster() {
    int idx = rand.nextInt(monsters.length);
    return monsters[idx];
  }

  void _loadCharacter() {
    stdout.write('캐릭터 이름을 입력하세요: ');
    String? name;
    final nameReg = RegExp(r'^[가-힣a-zA-Z]+$'); //이상하게 입력하기 방지
    while (true) {
      name = stdin.readLineSync()?.trim();
      if (name != null && nameReg.hasMatch(name)) break;
      stdout.write('유효한 이름을 입력하세요(한글/영문만): ');
    }
    try { 
      List<String> parts = File('characters.txt').readAsStringSync().split(',');
      int h = int.parse(parts[0]);
      int a = int.parse(parts[1]);
      int d = int.parse(parts[2]);
      character = Character(name, h, a, d);
      print('게임을 시작합니다!');
      print('${character.name} - 체력 : ${character.health}, 공격력 : ${character.attackPower}, 방어력 : ${character.defense}');
    } catch (e) {
      print('캐릭터 데이터를 불러오지 못했습니다: \$e');
      exit(1);
    }
  }

  void _bonusHealth() { // 30%의 확률로 캐릭터 보너스 체력 주기
    if (rand.nextDouble() < 0.3) {
      character.health += 10;
      print('보너스 체력을 얻었습니다! 현재 체력: ${character.health}');
    }
  }

  void _loadMonsters() {
    try {
      List<String> lines = File('monsters.txt').readAsLinesSync();
      print('\n새로운 몬스터가 나타났습니다!');
      for (String line in lines) {
        List<String> cols = line.split(',');
        monsters.add(Monster(cols[0], int.parse(cols[1]), int.parse(cols[2])));
       /// print('${cols[0]} - 체력 : ${cols[1]}, 공격력 : ${cols[2]}'); 싸울 때 출력하자
      }
    } catch (e) {
      print('몬스터 데이터를 불러오지 못했습니다: \$e');
      exit(1);
    }
  }

  void _saveResult(bool win) { //데이터 저장하기
    stdout.write('결과를 저장하시겠습니까? (y/n): ');
    String? yn = stdin.readLineSync();
    if (yn?.toLowerCase() == 'y') {
      String result = "${character.name},${character.health},${win ? '승리' : '패배'}";
      File('result.txt').writeAsStringSync(result);
      print('result.txt에 저장되었습니다.');
    }
  }
}

void main() {
  Game game = Game();
  game.startGame();
}

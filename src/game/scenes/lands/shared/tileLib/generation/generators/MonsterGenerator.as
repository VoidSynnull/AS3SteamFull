package game.scenes.lands.shared.tileLib.generation.generators {

	/**
	 * This is a land generator that randomly spawns monsters ONCE whene a scene is created.
	 * for a constant spawner, you'd need a system, not a generator.
	 */

	import game.data.character.CharacterData;
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.monsters.MonsterBuilder;
	import game.scenes.lands.shared.monsters.MonsterData;
	import game.scenes.lands.shared.monsters.components.LandMonster;
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;

	public class MonsterGenerator extends MapGenerator {

		private var group:LandGroup;

		private var builder:MonsterBuilder;

		public function MonsterGenerator( group:LandGroup, monsterBuilder:MonsterBuilder ) {

			super();

			this.group = group;
			this.builder = monsterBuilder;

		} //

		public function makeMonsters( gameData:LandGameData=null, maxMonsters:int=4, perMonsterChance:Number=0.2 ):Boolean {

			/**
			 * ugh i know. maybe fix later.
			 */
			var tile:LandTile;
			var c:int, r:int;

			var landMonster:LandMonster;
			var monsterData:MonsterData;
			var charData:CharacterData;

			var loadCount:int = 0;
			var count:int = maxMonsters*Math.random();
			while ( count-- > 0 && Math.random() < perMonsterChance ) {

				c = Math.random()*this.tileMap.cols;
				r = this.getTopRow( this.tileMap, c );
				if ( c < 0 ) {
					continue;
				}

				monsterData = this.builder.randomMonsterData();

				landMonster = new LandMonster();

				landMonster.mood = 20 + 50*Math.random();

				landMonster.data = monsterData;

				loadCount++;

				trace( "MONSTER TOP ROW: " + r );

				// build monster at row,col
				charData = this.builder.getMonsterCharData( monsterData, this.tileMap.tileSize*( c + 0.5 ), this.tileMap.tileSize*( r + 0.5 ) );

				this.builder.loadMonster( charData, landMonster );

			} //

			return ( loadCount > 0 );

		} // generate()

		public function setMap( tileMap:TileMap ):void {

			this.tileMap = tileMap;
			this.tileSet = tileMap.tileSet;

		} //

	} // class

} // package
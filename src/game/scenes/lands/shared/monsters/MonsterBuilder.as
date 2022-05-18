package game.scenes.lands.shared.monsters {
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Display;
	import engine.components.Interaction;
	
	import game.components.entity.character.CharacterMotionControl;
	import game.components.scene.SceneInteraction;
	import game.data.character.CharacterData;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.data.game.GameEvent;
	import game.scene.template.CharacterGroup;
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.components.HitTileComponent;
	import game.scenes.lands.shared.components.Life;
	import game.scenes.lands.shared.monsters.components.LandMonster;
	import game.scenes.lands.shared.monsters.nodes.MonsterNode;
	import game.scenes.virusHunter.heart.components.ColorBlink;
	import game.util.SkinUtils;

	public class MonsterBuilder {

		public const MIN_SCALE:Number = 0.5;
		public const MAX_SCALE:Number = 2;

		/**
		 * String used to quickly convert index numbers to string values.
		 */
		private const IntEncodings:String = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/=";

		/**
		 * used to assign monsters arbitrary id names as they are created.
		 */
		static private var MonsterCount:int = 0;

		private var variants:Array;

		private var facial:Array;
		private var eyes:Array;
		private var marks:Array;

		private var mouth:Array;
		private var hair:Array;

		private var shirt:Array;
		private var pants:Array;
		private var overshirt:Array;
		private var overpants:Array;

		private var pack:Array;
		private var item:Array;

		private var skinColor:Array;
		private var hairColor:Array;

		/**
		 * gives type-limitations specific to a biome.
		 * biomeTypes[ biomeName ] = MonsterBiomeType object
		 * which in turn gives lists of indices for each part which are allowed for that biome.
		 */
		private var biomeTypes:Dictionary;

		/**
		 * monsters in the process of loading.
		 */
		private var loadingMonsters:Vector.<Entity>;
		private var charGroup:CharacterGroup;
		private var landGroup:LandGroup;

		/**
		 * onMonstersLoaded( loadedMonsters:Vector.<Entity> )
		 */
		public var onMonstersLoaded:Function;

		public function MonsterBuilder( landGroup:LandGroup, charGroup:CharacterGroup ) {

			this.landGroup = landGroup;
			this.charGroup = charGroup;
			charGroup.addCompleteListener( this.monstersLoaded );
			charGroup.addToolTips = false;

			this.loadingMonsters = new Vector.<Entity>();
			this.biomeTypes = new Dictionary();

		} //

		public function addBiomeType( biome:String, biomeType:BiomeMonsterType ):void {

			this.biomeTypes[ biome ] = biomeType;

		} //

		private function monstersLoaded():void {

			var e:Entity;
			var monster:LandMonster;
			var life:Life;
			var motionControl:CharacterMotionControl;

			for( var i:int = this.loadingMonsters.length-1; i >= 0; i-- ) {

				e = this.loadingMonsters[i];

				monster = e.get( LandMonster ) as LandMonster;

				life = new Life( 30*monster.data.scale, 0.5*monster.data.scale );
				e.add( life, Life );

				e.add( new ColorBlink( 0x880000, 0.43, 0.5 ), ColorBlink );

				/**
				 * monsters shouldnt be clickable. this might change in the future.
				 */
				e.remove( SceneInteraction );
				e.remove( Interaction );
				//( e.get( Display ) as Display ).disableMouse();

				//trace( "MONSTER Y: " + ( e.get(Spatial) as Spatial ).y );
				// this will track what tile is being hit by the monster and do special tile actions...
				e.add( new HitTileComponent(), HitTileComponent );

				this.charGroup.addFSM( e );

				// might need to get the mood now to perform actions that werent allowed before char loading.
				motionControl = e.get( CharacterMotionControl );
				if ( motionControl ) {
					motionControl.runSpeed = 300;
					motionControl.maxVelocityX = 400;
				}
				
			} //

			if ( this.onMonstersLoaded ) {
				this.onMonstersLoaded( this.loadingMonsters );
			}

			this.loadingMonsters.length = 0;

		} //

		public function loadMonster( charData:CharacterData, monster:LandMonster ):void {

			var entity:Entity = this.charGroup.createNpcFromData( charData );
			entity.add( monster, LandMonster );

			this.loadingMonsters.push( entity );

		} //

		/**
		 * get an xml node with child nodes containing monster data for every "multiScene" monster.
		 * returns null if none are present in the scene.
		 * 
		 * since these monsters are changing scenes, their x,y is not currently important,
		 * though it might become important if monsters are able to change scenes
		 * independently of the player.
		 */
		public function getMultiSceneMonsterXML():XML {

			var monsterList:NodeList = this.landGroup.systemManager.getNodeList( MonsterNode );
			if ( monsterList.head == null ) {
				return null;	// no monsters.
			}

			var monster:LandMonster;
			var xmlNode:XML;

			var xmlParent:XML = <monsters />;

			for( var node:MonsterNode = monsterList.head; node; node = node.next ) {

				monster = node.monster;
				
				if ( !monster.multiScene ) {
					// function gets xml for monsters that are moving from scene to scene.
					continue;
				}

				//x={Math.round( node.spatial.x )} y={Math.round(node.spatial.y)} save for restoring monster x,y
				xmlNode =
					<npc mood={monster.mood} dna={this.encodeMonsterLook(monster.data)} />;
				xmlParent.appendChild( xmlNode );
				
			} // end for-loop.

			return xmlParent;

		} //

		/**
		 * load monsters defined in the xml. if no position is specified in the child xml nodes,
		 * the monsters are assumed to be following the player, and are placed near the provided coordinates.
		 */
		public function loadMultiSceneMonsters( monsterXML:XML, playerX:Number, playerY:Number ):void {

			var children:XMLList = monsterXML.children();
			var count:int = children.length();
			var monster:LandMonster;

			var node:XML;

			for( var i:int = 0; i < count; i++ ) {

				node = children[i];

				monster = new LandMonster();
				monster.mood = node.@mood;
				monster.data = this.decodeMonsterLook( node.@dna );

				if ( node.hasOwnProperty( "@x" ) ) {
					this.loadMonster( this.getMonsterCharData( monster.data, node.@x, node.@y ), monster );
				} else {
					// use the default position plus random offset.
					this.loadMonster( this.getMonsterCharData( monster.data, playerX - 40 + 80*Math.random(), playerY ), monster );
				} //

			} //

		} //

		/**
		 * load all the monsters defined in an xml node.
		 */
		public function loadSceneMonsters( monsterList:XMLList ):void {

			var len:int = monsterList.length();
			var npcXML:XML;
			var monster:LandMonster;
			
			for( var i:int = len-1; i >= 0; i-- ) {

				npcXML = monsterList[i];

				monster = new LandMonster();
				monster.mood = npcXML.@mood;
				monster.data = this.decodeMonsterLook( npcXML.@dna );

				this.loadMonster( this.getMonsterCharData( monster.data, npcXML.@x, npcXML.@y ), monster );

			} // end for-loop.
			
		} //

		/**
		 * save any creatures currently in the scene, except for creatures marked multiScene,
		 * since those are moving with the player.
		 * 
		 */
		public function saveMonsterXML( sceneParent:XML ):void {
			
			var monsterList:NodeList = this.landGroup.systemManager.getNodeList( MonsterNode );
			var monster:LandMonster;
			var xmlNode:XML;

			for( var node:MonsterNode = monsterList.head; node; node = node.next ) {
				
				monster = node.monster;
				
				xmlNode =
					<npc mood={monster.mood} x={Math.round( node.spatial.x )} y={Math.round(node.spatial.y)} dna={this.encodeMonsterLook(monster.data)} />;
				
				if ( monster.multiScene == true ) {

					continue;
				} else {
					sceneParent.appendChild( xmlNode );
				}
				
			} // end for-loop.

		} //

		public function randomMonsterData():MonsterData {

			var data:MonsterData = new MonsterData();

			var biomeType:BiomeMonsterType = this.biomeTypes[ this.landGroup.loadBiome ];

			// must be at least one variant.
			data.variantIndex = Math.random()*this.variants.length;

			data.facialIndex = this.getRandomPart( this.facial );
			data.eyeIndex = this.getRandomPart( this.eyes );
			data.mouthIndex = this.getRandomPart( this.mouth );
			data.marksIndex = this.getRandomPart( this.marks );
			data.hairIndex = this.getRandomPart( this.hair );
			data.shirtIndex = this.getRandomPart( this.shirt );
			data.pantsIndex = this.getRandomPart( this.pants );
			data.overshirtIndex = this.getRandomPart( this.overshirt );
			data.overpantsIndex = this.getRandomPart( this.overpants );
			data.packIndex = this.getRandomPart( this.pack );
			data.itemIndex = this.getRandomPart( this.item );

			if ( biomeType != null ) {

				var ind:int = biomeType.getRandomPartIndex( "skinColor" );
				if ( ind == -1 ) {
					data.skinColorIndex = this.getRandomPart( this.skinColor );
				} else {
					data.skinColorIndex = ind;
				}
				ind = biomeType.getRandomPartIndex( "hairColor" );
				if ( ind == -1 ) {
					data.hairColorIndex = this.getRandomPart( this.hairColor );
				} else {
					data.hairColorIndex = ind;
				}

			} else {

				data.skinColorIndex = this.getRandomPart( this.skinColor );
				data.hairColorIndex = this.getRandomPart( this.hairColor );

			} //

			data.scale = this.MIN_SCALE + Math.random()*( this.MAX_SCALE - this.MIN_SCALE );

			return data;

		} //

		private function getRandomPart( partArray:Array ):int {

			if ( partArray.length == 0 ) {
				return -1;
			}			
			return Math.random()*partArray.length;

		} //

		private function getBiomePart( part:String, biomeType:BiomeMonsterType ):int {

			var partArray:Array = this[ part ];
			if ( partArray.length == 0 ) {
				return -1;
			}

			if ( biomeType ) {

				var ind:int = biomeType.getRandomPartIndex( part );
				if ( ind != -1 ) {
					return ind;
				}
			}

			return Math.random()*partArray.length;

		} //

		/**
		 * when a monster is loaded into the scene, it actually needs to be created through the poptropica character system.
		 * this means it needs a 'CharacterData' object for initialization.
		 */
		public function getMonsterCharData( monsterData:MonsterData, x:int, y:int ):CharacterData {
				
			var charData:CharacterData = new CharacterData();

			charData.type = CharacterData.TYPE_NPC;
			charData.variant = this.variants[ monsterData.variantIndex ];

			charData.id = "m"+MonsterBuilder.MonsterCount++;

			charData.look = this.getMonsterLookData( monsterData );

			if ( Math.random() < 0.5 ) {
				charData.direction = "right";
			} else {
				charData.direction = "left";
			} //

			charData.scale = 0.3*monsterData.scale;

			charData.position.x = x;
			charData.position.y = y;
			charData.event = GameEvent.DEFAULT;

			return charData;

		} //

		public function getMonsterLookData( monsterData:MonsterData ):LookData {

			var lookData:LookData = new LookData();

			ind = monsterData.skinColorIndex;
			if ( ind >= 0 ) {
				lookData.applyAspect( new LookAspectData( SkinUtils.SKIN_COLOR, this.skinColor[ ind ] ) );
			}
			
			ind = monsterData.hairColorIndex;
			if ( ind >= 0 ) {
				lookData.applyAspect( new LookAspectData( SkinUtils.HAIR_COLOR, this.hairColor[ ind ] ) );
			}

			var ind:int = monsterData.facialIndex;
			if ( ind >= 0 ) {
				lookData.applyAspect( new LookAspectData( SkinUtils.FACIAL, this.facial[ ind ] ) );
			}

			ind = monsterData.eyeIndex;
			if ( ind >= 0 ) {
				lookData.applyAspect( new LookAspectData( SkinUtils.EYE_STATE, this.eyes[ ind ] ) );
			}
			ind = monsterData.mouthIndex;
			if ( ind >= 0 ) {
				lookData.applyAspect( new LookAspectData( SkinUtils.MOUTH, this.mouth[ ind ] ) );
			}
			ind = monsterData.hairIndex;
			if ( ind >= 0 ) {
				lookData.applyAspect( new LookAspectData( SkinUtils.HAIR, this.hair[ ind ] ) );
			}
			ind = monsterData.marksIndex;
			if ( ind >= 0 ) {
				lookData.applyAspect( new LookAspectData( SkinUtils.MARKS, this.marks[ ind ] ) );
			}

			ind = monsterData.shirtIndex;
			if ( ind >= 0 ) {
				lookData.applyAspect( new LookAspectData( SkinUtils.SHIRT, this.shirt[ ind ] ) );
			}
			ind = monsterData.pantsIndex;
			if ( ind >= 0 ) {
				lookData.applyAspect( new LookAspectData( SkinUtils.PANTS, this.pants[ ind ] ) );
			}

			ind = monsterData.overshirtIndex;
			if ( ind >= 0 ) {
				lookData.applyAspect( new LookAspectData( SkinUtils.OVERSHIRT, this.overshirt[ ind ] ) );
			}

			ind = monsterData.overpantsIndex;
			if ( ind >= 0 ) {
				lookData.applyAspect( new LookAspectData( SkinUtils.OVERPANTS, this.overpants[ ind ] ) );
			}

			ind = monsterData.packIndex;
			if ( ind >= 0 ) {
				lookData.applyAspect( new LookAspectData( SkinUtils.PACK, this.pack[ ind ] ) );
			}

			ind = monsterData.itemIndex;
			if ( ind >= 0 ) {
				lookData.applyAspect( new LookAspectData( SkinUtils.ITEM, this.item[ ind ] ) );
			}


			return lookData;

		} //

		/**
		 * encodes a monster look and mood, and any other "monster" data that might be needed later on.
		 */
		public function encodeMonsterXML( monster:LandMonster ):XML {

			return <monster mood={monster.mood} look={this.encodeMonsterLook(monster.data)} />;

		} //

		/**
		 * note that before the monster data is encoded, indices are incremented by 1 to
		 * avoid encoding invalid (-1) indices.
		 */
		public function encodeMonsterLook( data:MonsterData ):String {

			var output:String = "";

			output += this.IntEncodings.charAt( data.variantIndex+1 );

			output += this.IntEncodings.charAt( data.facialIndex+1 );
			output += this.IntEncodings.charAt( data.eyeIndex+1 );
			output += this.IntEncodings.charAt( data.mouthIndex+1 );
			output += this.IntEncodings.charAt( data.hairIndex+1 );
			output += this.IntEncodings.charAt( data.marksIndex+1 );

			output += this.IntEncodings.charAt( data.shirtIndex+1 );
			output += this.IntEncodings.charAt( data.pantsIndex+1 );
			output += this.IntEncodings.charAt( data.overshirtIndex+1 );
			output += this.IntEncodings.charAt( data.overpantsIndex+1 );

			output += this.IntEncodings.charAt( data.packIndex+1 );
			output += this.IntEncodings.charAt( data.itemIndex+1 );

			output += this.IntEncodings.charAt( data.skinColorIndex+1 );
			output += this.IntEncodings.charAt( data.hairColorIndex+1 );
			output += this.IntEncodings.charAt( data.scale*10 );

			return output;

		} //

		/**
		 * decoded monsters need to have their indices decremented by 1.
		 */
		public function decodeMonsterLook( str:String ):MonsterData {

			var data:MonsterData = new MonsterData();

			var index:int = 0;

			data.variantIndex = this.IntEncodings.indexOf( str.charAt(index++) ) - 1;

			data.facialIndex = this.IntEncodings.indexOf( str.charAt(index++) ) - 1;
			data.eyeIndex = this.IntEncodings.indexOf( str.charAt(index++) ) - 1;
			data.mouthIndex = this.IntEncodings.indexOf( str.charAt(index++) ) - 1;
			data.hairIndex = this.IntEncodings.indexOf( str.charAt(index++) ) - 1;
			data.marksIndex = this.IntEncodings.indexOf( str.charAt(index++) ) - 1;

			data.shirtIndex = this.IntEncodings.indexOf( str.charAt(index++) ) - 1;
			data.pantsIndex = this.IntEncodings.indexOf( str.charAt(index++) ) - 1;
			data.overshirtIndex = this.IntEncodings.indexOf( str.charAt(index++) ) - 1;
			data.overpantsIndex = this.IntEncodings.indexOf( str.charAt(index++) ) - 1;

			data.packIndex = this.IntEncodings.indexOf( str.charAt(index++) ) - 1;
			data.itemIndex = this.IntEncodings.indexOf( str.charAt(index++) ) - 1;

			data.skinColorIndex = this.IntEncodings.indexOf( str.charAt(index++) ) - 1;
			data.hairColorIndex = this.IntEncodings.indexOf( str.charAt(index++) ) - 1;

			data.scale = this.IntEncodings.indexOf( str.charAt(index++) )/10;

			return data;

		} //

		/**
		 * simple function to allow the monster property arrays to be set by name.
		 * not really necessary if the property arrays were made public, or if
		 * an accessor was made for each one.
		 */
		public function setPropertyList( propName:String, list:Array ):void {

			this[ propName ] = list;

		} //

	} // class

} // package
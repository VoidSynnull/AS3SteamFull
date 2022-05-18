package game.scenes.gameJam.dancingZombie
{
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.motion.ShakeMotion;
	import game.components.timeline.Timeline;
	import game.creators.entity.character.CharacterCreator;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.TextDisplayCreator;
	import game.data.animation.entity.character.Attack;
	import game.data.animation.entity.character.DanceMoves01;
	import game.data.animation.entity.character.Disco;
	import game.data.animation.entity.character.FistPunch;
	import game.data.animation.entity.character.Guitar;
	import game.data.animation.entity.character.RobotDance;
	import game.data.animation.entity.character.Sing;
	import game.data.animation.entity.character.Stand;
	import game.data.character.LookData;
	import game.data.character.PartDefaults;
	import game.managers.EntityPool;
	import game.scene.template.CharacterGroup;
	import game.scenes.gameJam.dancingZombie.components.BeatDriven;
	import game.scenes.gameJam.dancingZombie.components.DanceAttack;
	import game.scenes.gameJam.dancingZombie.components.DiscoTile;
	import game.scenes.gameJam.dancingZombie.components.Zombie;
	import game.scenes.gameJam.dancingZombie.systems.BeatDriverSystem;
	import game.scenes.gameJam.dancingZombie.systems.DiscoTileSystem;
	import game.scenes.gameJam.dancingZombie.systems.ZombieSystem;
	import game.scenes.mocktropica.server.component.SwitchValue;
	import game.systems.motion.ShakeMotionSystem;
	import game.ui.elements.ConfirmationDialogBox;
	import game.ui.popup.Popup;
	import game.util.ArrayUtils;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.ColorUtil;
	import game.util.DataUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TextUtils;
	import game.util.TweenUtils;
	
	public class DanceGamePopup extends Popup
	{
		
		public function DanceGamePopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			screenAsset = "gameJamDemo.swf";
			groupPrefix = "scenes/gameJam/dancingZombie/";
			super.init(container);
			load();
		}
		
		override public function load():void
		{
			// prolly going to load in data for set up later
			SoundManager(shellApi.getManager(SoundManager)).cache(SoundManager.MUSIC_PATH+"discoDescent.mp3");
			super.loadFiles([ this.screenAsset, "levels.xml", "patterns.xml" ], false, true, this.loaded );
		}
		
		override public function loaded():void
		{
			//super.preparePopup();
			super.screen = super.getAsset(this.screenAsset, true) as MovieClip;
			this.letterbox(this.screen.content, new Rectangle(0, 0, shellApi.viewportWidth, shellApi.viewportHeight), false);
			this.darkenAlpha = 0.85;
			
			_tileHeight = shellApi.viewportHeight / ROWS_TOTAL;
			_tileWidth = shellApi.viewportWidth / COLS_TOTAL;

			_contentClip = screen.content;
			_contentClip.x = _contentClip.y = 0
			
			_floorClip = _contentClip["floor"];
			_floorClip.y = 0;
			_floorClip.x = _tileWidth/2 ;

			_characterGroup = new CharacterGroup();
			_characterGroup.setupGroup(this,_contentClip["floor"]);
			
			parseLevel();
			
			setUpZombies();
			
			setupBeatSystems();
			
			// this eventually leads to popup being ready
			setUpFloor();	
		}
		
		////////////////////////////// SETUP //////////////////////////////
		
		private function parseLevel():void
		{
			_rows = new Vector.<Array>();
			var levelXml:XML = super.getData( "levels.xml" );
			var rowsXMLList:XMLList = levelXml.children();
			for (var i:int = 0; i < rowsXMLList.length(); i++) 
			{
				_rows.push( DataUtils.getArray( rowsXMLList[i] ) )
			}
		}
		
		private function setUpZombies():void
		{
			addSystem(new ZombieSystem());
			_zombiePool = new EntityPool();
			_zombiePool.setSize("any",MAX_ZOMBIES);
			var zombie:Entity;
			var look:LookData;
			for(var i:int = 0 ; i < MAX_ZOMBIES; i++)
			{
				zombie = _characterGroup.createDummy("zombie"+i,getZombieLookData(),"right","",_contentClip,null,zombieCreated,true,char_Scale, "dummy", new Point(0, _tileHeight * .25) );
			}
		}
		
		public function getZombieLookData(gender:String = ""):LookData
		{
			var lookData:LookData = new LookData();
			
			if(!DataUtils.validString(gender)) gender = ArrayUtils.getRandomElement([SkinUtils.GENDER_MALE, SkinUtils.GENDER_FEMALE]);
			
			var skinColor:Number	= 0x606A9F;
			var hairColor:Number 	=  0x3D3F86;
			var marks:String 		= "z_zombie";
			var mouth:String 		= "z_zombie";
			var eyes:String 		= "zombie";
			
			var facial:String;
			var hair:String;
			var pants:String;
			var shirt:String;
			
			switch(gender)
			{
				case SkinUtils.GENDER_MALE:
					facial 	= ArrayUtils.getRandomElement(this.facialBoy);
					hair 	= ArrayUtils.getRandomElement(this.hairBoy);
					pants 	= ArrayUtils.getRandomElement(this.pantsBoy);
					shirt 	= ArrayUtils.getRandomElement(this.shirtBoy);
					break;
				
				case SkinUtils.GENDER_FEMALE:
					facial 	= ArrayUtils.getRandomElement(this.facialGirl);
					hair 	= ArrayUtils.getRandomElement(this.hairGirl);
					pants 	= ArrayUtils.getRandomElement(this.pantsGirl);
					shirt 	= ArrayUtils.getRandomElement(this.shirtGirl);
					break;
				
				default:
					throw new Error("PartDefaults :: randomLookData() :: A gender of " + gender + " is invalid");
					break;
			}
			
			lookData.applyLook(gender, skinColor, hairColor, "", marks, mouth, facial, hair, pants, shirt);
			return lookData;
		}
		
		private function zombieCreated(zombieEntity:Entity):void
		{
			_zombiePool.release(zombieEntity);
			
			var zom:Zombie = new Zombie(_tileHeight);
			zom.stateChanged.add(zombieStateChanged);
			
			zombieEntity.add(zom);
			zombieEntity.add(new BeatDriven());
			zombieEntity.add( new Sleep( true, true ) );
			EntityUtils.visible(zombieEntity, false);
			
			// lock zombie parts
			SkinUtils.getSkinPart( zombieEntity, SkinUtils.MOUTH ).lock = true;
			// remove interactions
			EntityUtils.removeInteraction( zombieEntity );
		}
		
		private function zombieStateChanged(zombieEntity:Entity, state:String):void
		{
			var zom:Zombie = zombieEntity.get(Zombie);
			switch(state)
			{
				case ZombieSystem.REACHED:
				{
					// hurt the band, get rid of zombie
					_bandHealth -= 1;
					trace("zom:"+zombieEntity.get(Id).id+" hit band, HP: "+_bandHealth);
					if(0 >= _bandHealth){
						// YOU LOSE
						var popup:ConfirmationDialogBox = this.addChildGroup(new ConfirmationDialogBox(2,"The zomberries got you!, try again?",restartGame,closeGame)) as ConfirmationDialogBox;
						popup.darkenBackground = true;
						popup.init( _contentClip );
					}
					
					zom.active = false;
					CharUtils.setAnim(zombieEntity, Attack);
					TweenUtils.entityTo( zombieEntity, Display, .6, {alpha:0, ease:Sine.easeIn})
					SceneUtil.delay( this, .6, Command.create(zombieFaded, zombieEntity) );
					break;
				}
				case ZombieSystem.DEAD:
				{
					// dance that zombie off the stage
					// ignore for now
					break;
				}
			}
		}
		
		private function closeGame(...p):void
		{
			//this.close();
			// no close, you're trapped forever!
			shellApi.loadScene(DancingZombie);
		}
		
		private function restartGame():void
		{
			shellApi.loadScene(DancingZombie);
		}
		
		private function setUpFloor():void
		{
			_tileSystem = new DiscoTileSystem();
			addSystem(_tileSystem);
			
			_tiles = new Vector.<Vector.<Entity>>
			
			this.loadFile("tile.swf", Command.create(createTile, 1, 0));
		}
		
		private function createTile(clip:MovieClip, row:int, col:int ):void
		{
			clip = clip["tile"];
			var tileClip:MovieClip = clip["tileClip"];
			tileClip.width = _tileWidth;
			tileClip.height = _tileHeight;
			
			clip.x = (col * _tileWidth);
			clip.y = row * _tileHeight - _tileHeight/2;
			
			var tileEntity:Entity = EntityUtils.createSpatialEntity(this, clip, _floorClip);
			tileEntity.add(new Id("tile"+col+"_"+row));
			var discoTile:DiscoTile = new DiscoTile();
			discoTile.beatMeasure = (row % MAX_MEASURE);
			discoTile.colorIndex = row + col;
			discoTile.row = row;
			discoTile.column = col;
			tileEntity.add(discoTile);
			tileEntity.add(new BeatDriven());
			
			//tileClip.text.text = "R:"+row+",C:"+col;
			tileClip.text.text = " ";
			TextUtils.refreshText(tileClip.text);
				
			var tileRow:Vector.<Entity>;
			if( row > _tiles.length )
			{
				tileRow = new Vector.<Entity>();
				_tiles.push( tileRow );
			}
			else
			{
				tileRow = _tiles[ row - 1 ];
			}
			tileRow.push( tileEntity );
			
			// recurse until last row, then create band slots
			col++;
			if( col == COLS_TOTAL )
			{
				row++;
				if( row == ROWS_TOTAL)
				{
					setupBand();
					return;
				}
				col = 0;
			}
			this.loadFile("tile.swf", Command.create(createTile, row, col));
		}
		
		private function setupBand():void
		{
			super.addSystem( new ShakeMotionSystem() );
			_tiles.push( new Vector.<Entity>() );
			this.loadFile("band_tile.swf", Command.create(createBandSlot, 0));
		}
		
		private function createBandSlot(clip:MovieClip, col:int):void
		{
			clip = clip["tile"];
			var tileClip:MovieClip = clip["tileClip"];
			tileClip.width = _tileWidth;
			tileClip.height = _tileHeight;
			clip.x = (col * _tileWidth);
			clip.y = _tileHeight * (ROWS_TOTAL - 1) + _tileHeight/2;
			var bandSlot:Entity = EntityUtils.createSpatialEntity(this, clip, _floorClip);
			
			bandSlot.add(new Id("tile"+col+"_"+0));
			
			var discoTile:DiscoTile = new DiscoTile();
			discoTile.beatMeasure = 0;
			discoTile.row = ROWS_TOTAL;
			discoTile.column = col;
			discoTile.ignoreColor = true;
			
			// load up attack pattern for musician
			var danceAttack:DanceAttack = new DanceAttack(patternsTypes[col] ,this.getData("patterns.xml"));
			bandSlot.add(danceAttack);
			
			bandSlot.add(discoTile);
			bandSlot.add(new BeatDriven());
			
			var shake:ShakeMotion = new ShakeMotion();
			bandSlot.add(shake);
			
			_tiles[ROWS_TOTAL-1].push(bandSlot);
			
			var lookData:LookData = new LookData();
			var gender:String = ( (Math.random() * 2) > 1 ) ? SkinUtils.GENDER_FEMALE : SkinUtils.GENDER_MALE;
			_partDefaults.randomLookData(lookData, gender);
			lookData.setValue( SkinUtils.ITEM, instruments[col] );
			
			
			var position:Point = new Point( 0, _tileHeight/4 );
			var bandMember:Entity = _characterGroup.createDummy("bandMember"+col, lookData, "left", "", clip, null, onBandMemberCreated, true, char_Scale, CharacterCreator.TYPE_DUMMY, position );
			EntityUtils.addParentChild( bandMember, bandSlot );
			ButtonCreator.assignButtonEntity( bandSlot, clip, this, tapBeat, null, null, null, false);
			
			col++;
			if( col < COLS_TOTAL )
			{
				this.loadFile( "band_tile.swf", Command.create(createBandSlot, col) );
			}
			else
			{
				super.loaded();
				this.groupReady();
				SceneUtil.delay( this, 2, startBeats );
			}
		}
		
		private function onBandMemberCreated(bandMember:Entity):void
		{
			EntityUtils.removeInteraction( bandMember );
		}
		
		private function setupBeatSystems():void
		{
			_beatSystem = new BeatDriverSystem();
			
			_beatSystem.beatLength 	= BEAT_LENGTH;
			_beatSystem.beatWindow 	= BEAT_WINDOW;
			_beatSystem.beatLatency = BEAT_LATENCY;
			super.addSystem( _beatSystem );
			
			_beatEntity = new Entity();
			_beatEntity.add( new BeatDriven() );
			super.addEntity( _beatEntity );
		}
		
		private function startBeats():void
		{
			_beatSystem.onBeat.add( onBeat );
			_beatSystem.start();
			AudioUtils.play(this, SoundManager.MUSIC_PATH+"discoDescent.mp3");
		}
		
		////////////////////////////// GAME LOOP //////////////////////////////
		
		private function onBeat():void
		{
			_beatCount++;
			if(_beatCount >= 3 )
			{
				spawnZombie();
				_beatCount = 0;
			}
		}
		
		private function spawnZombie():void
		{
			//createZombieCharacter(int(Math.random() * COLS_TOTAL), Math.ceil(Math.random() * 4));
			
			// pull row from array, spawn all zombies in it
			var row:Array = _rows.shift();
			trace("spawn row:"+row)
			if( row )
			{
				var zombieType:int;
				for (var i:int = 0; i < row.length; i++) 
				{
					zombieType = row[i];
					if( zombieType > 0 )
					{
						createZombieCharacter(i,zombieType);
					}
				}
			}
			else
			{
				// switch to ramdomization
				createZombieCharacter(int(Math.random() * COLS_TOTAL), Math.ceil(Math.random() * 4));
			}
		}
		
		private function createZombieCharacter(col:int,health:int):void
		{
			var zombieEntity:Entity = _zombiePool.request();
			if(zombieEntity == null)
				return;
			var zom:Zombie = zombieEntity.get(Zombie);
			zom.health = health;
			zom.beatMovements = [health];
			
			SkinUtils.setSkinPart( zombieEntity, SkinUtils.SKIN_COLOR, _zombieSkinColors[health-1] );
			SkinUtils.setSkinPart( zombieEntity, SkinUtils.HAIR_COLOR, _zombieHairColors[health-1] );
			SkinUtils.setSkinPart( zombieEntity, SkinUtils.EYES, "zombie" );
			CharUtils.setAnim(zombieEntity, Stand);
			
			zom.coordinates = new Point(col, 0);
			
			(zombieEntity.get(Sleep) as Sleep ).sleeping = false;
			
			(zombieEntity.get(BeatDriven) as BeatDriven ).beatHit = false;
			zom.active = true;
		}
		
		private function tapBeat( bandSlot:Entity):void
		{
			var colorClip:MovieClip = MovieClip(EntityUtils.getDisplayObject(bandSlot))["tileClip"]["colorClip"];
			//trace("tap"+beat);
			if( _beatSystem.inBeatRange() )
			{
				var danceattack:DanceAttack = bandSlot.get(DanceAttack);
				
				var col:int = (bandSlot.get(DiscoTile) as DiscoTile).column;
				//lightColumn( col );
				lightPath(danceattack);
				
				var bandMember:Entity = EntityUtils.getChildById(bandSlot, "bandMember"+col);
				if( col == 2 )
				{
					//CharUtils.setAnim( bandMember, LeadSinger, false, BEAT_LENGTH );
					CharUtils.setAnim( bandMember, Sing, false, BEAT_LENGTH );
				}
				else
				{
					CharUtils.setAnim( bandMember, Guitar );
				}		
				
				// TODO :: Update bandMember tile color, play animation, play particle, light up floor
				var zombie:Entity;
				var zom:Zombie;
				// make character fire
				for (var z:int = 0; z < MAX_ZOMBIES; z++)
				{
					zombie = getEntityById("zombie"+z);
					zom = zombie.get(Zombie);
					if(zom.inPath(danceattack.patternPoints) && zom.health > 0)
					{
						// hit zombies
						zom.health--;
						// adjust skin & hair color by health
						trace("zomHp:"+zom.health);
						if(zom.health <= 0)
						{
							// stop movement allong tiles, change look to human
							zom.active = false;
							SkinUtils.setRandomSkinColors( zombie );
							SkinUtils.setSkinPart( zombie, SkinUtils.EYES, "eyes");
							CharUtils.setAnim(zombie, FistPunch);
							
							TweenUtils.entityTo( zombie, Display, .6, {alpha:0, ease:Sine.easeIn})
							SceneUtil.delay( this, .6, Command.create(zombieFaded, zombie) );
						}
						else
						{
							SkinUtils.setSkinPart( zombie, SkinUtils.SKIN_COLOR, _zombieSkinColors[zom.health-1] );
							SkinUtils.setSkinPart( zombie, SkinUtils.HAIR_COLOR, _zombieHairColors[zom.health-1] );
							
							var randomNum:int = GeomUtils.randomInt(1,3);
							if( randomNum == 1 )
							{
								CharUtils.setAnim(zombie, DanceMoves01);
							}
							else if( randomNum == 2 )
							{
								CharUtils.setAnim(zombie, RobotDance);
							}
							else
							{
								CharUtils.setAnim(zombie, Disco);
							}
							Timeline(zombie.get(Timeline)).handleLabel("ending", Command.create(CharUtils.setAnim, zombie, Stand));
						}
					}
				}
			}
			else
			{
				ColorUtil.colorize(colorClip, 0xDB2316);
				// make character fail
				// TODO :: Update bandMember tile color, play animation, sour note/scratch, shake tile
				
			}
		}
		
		private function zombieFaded( zombieEntity:Entity ):void
		{
			EntityUtils.getDisplay(zombieEntity).alpha = 1;
			EntityUtils.visible(zombieEntity,false,true);
			(zombieEntity.get(Sleep) as Sleep).sleeping = true;
			_zombiePool.release(zombieEntity);
		}
		
		private function lightColumn( col:int ):void
		{
			var tileEntity:Entity;
			for (var row:int = 0; row < ROWS_TOTAL; row++) 
			{
				tileEntity = getTileEntity( row, col);
				if( tileEntity )
				{
					lightTile(tileEntity);
				}
			}
		}
		
		private function lightPath( dance:DanceAttack ):void
		{
			var path:Vector.<Point> = dance.patternPoints;
			var tileEntity:Entity;
			for (var i:int = 0; i < path.length; i++) 
			{
				tileEntity = getTileEntity( path[i].y-1, path[i].x);
				if( tileEntity )
				{
					SceneUtil.delay(this,i*(0.08),Command.create(lightTile,tileEntity));
				}
			}
		}
		
		private function lightTile(tileEntity:Entity):void
		{
			EntityUtils.getDisplayObject(tileEntity)["tileClip"]["colorClip"].alpha = 1;
			DiscoTile(tileEntity.get(DiscoTile)).lit = true;
		}
		
		public function getTileEntity( row:int, col:int ):Entity
		{
			if (_tiles)
			{
				if( row < ROWS_TOTAL )
				{
					return _tiles[row][col];
				}
			}
			return null;
		}
		
		private const BEAT_LENGTH:Number = .52174;	//seconds
		private const BEAT_WINDOW:Number = .17;		//seconds
		private const BEAT_LATENCY:Number = .2;		//seconds
		private const MAX_MEASURE:int = 4;		
		private const MAX_ZOMBIES:int = 32;
		public const ROWS_TOTAL:int = 6;//8
		public const COLS_TOTAL:int = 5;//4
		
		private var char_Scale:Number = .4; // for landscpae.4; // for landscpae.55;
		
		private var _zombieSkinColors:Vector.<Number> = new<Number>[0X66CCFF, 0x32B6D7, 0x606A9F, 0x43316B];
		private var _zombieHairColors:Vector.<Number> = new<Number>[0x3378CF, 0x335FB7, 0x3C3F86, 0x371554];
		
		private var _tiles:Vector.<Vector.<Entity>>;
		
		private var _rows:Vector.<Array>
		private var _wave:int = 0;
		private var _partDefaults:PartDefaults = new PartDefaults();
		private var _beatSystem:BeatDriverSystem;
		private var _tileSystem:DiscoTileSystem;
		private var _beatEntity:Entity;
		private var _characterGroup:CharacterGroup;
		private var _contentClip:MovieClip;
		private var _floorClip:MovieClip;
		private var _zombiePool:EntityPool;
		
		private var _tileHeight:int;
		private var _tileWidth:Number;

		private var _zombieWave:Array = new Array();
		private var _beatCount:int = 0;
		
		private var _bandHealth:int = 10;

		// dance attack patterns
		public const patternsTypes:Array  = ["vertical0", "turnRight1", "cross5", "turnLeft3", "vertical4"];

		public const instruments:Array  = [ "guitar", "ppunkguy1", "microphone", "ppunkgirl1"];
		//public const instruments:Array  = [ "guitar", "ppunkguy1", "microphone", "ppunkgirl1"];
		
		public const facialBoy:Array 	= ["empty", "empty", "empty", "empty", "empty", "empty", "empty", "empty", "empty", 2, "bl_drem", "mk_writer", "mk_disgruntled_programmer", "nateg", "realityteen", "ss"];
		public const facialGirl:Array 	= ["empty", "empty", "empty", "empty", "empty", "empty", "empty", "empty", "empty", 2, 4, "bl_drem", "bl_critic02", "curator", "librarian", "mk_cutter", "nateg", "realityteen", "sponsor_LM_Stella", "ss"];
		
		public const hairBoy:Array 	= [1, 6, 7, 9, 10, 22, 26, 34, 35, 36, 44, "prisoner1", "z_disco2", "gasDude", "gulliver", "lc_slayton", "mc_loverboy", "nateg", "realityteen", "referee", "SRishmael", "tourguide", "VCgothBoy", "wwprisoner"];
		public const hairGirl:Array	= [1, 23, 27, 29, 32, 39, 40, 43, "z_disco4", "bl_barf", "curator", "girlhair4", "girlhair5", "girlhair6", "mikesmarket", "mtdancer", "mthtownie02", "mythbeach2", "sears1", "sears2", "sears3", "soccer", "sponsorAuntOpal", "sponsorfarmgirl", "SRishmael", "srmom", "srstubb", "srstarbuck", "VCgothGirl", "z_disco3"];
		
		public const pantsBoy:Array 	= [1, 2, 3, 6, 10, "z_dancer1", "wwannouncer", "adams", "astroalien1", "astroalien3", "astrofarmer", "astroking", "astrogossip3", "astroguard1", "astrozone", "conworker1", "eiffel", "finvendor", "mc_junior"];
		public const pantsGirl:Array 	= [1, 2, 3, 4, 8, 9, 10, 12, 14, "adams", "astroalien1", "astroalien2", "astroalien4", "astroguard1", "astrozone", "balloonpilate01", "bl_cashier", "buckyfan", "conworker1", "directord", "girlskirt1", "girlskirt2", "girlskirt3", "girlskirt4", "girlskirt5", "mc_junior", "sponsorMargo"];
		
		public const shirtBoy:Array 	= ["z_dancer1", "z_disco2", 1, 4, 5, 11, 13, 21, 22, 26, "balloonpilot02", "biker", "bl_cashier", "bl_dref", "bl_drem", "bluetie", "boyshirt1", "counterres1", "counterres2", "edworker1", "gtinfoil", "hashimoto", "hiker", "lc_boy", "mikesmarket", "mime", "nw_burg", "nim2", "patron1", "realityboy", "sears4", "tourist", "wwman"];
		public const shirtGirl:Array	= ["z_disco3", "z_disco4", 2, 3, 4, 5, 7, 9, 10, 11, 12, 19, 23, 25, 26, "balloonpilot02", "biker", "bl_mom02", "bl_sofia", "counterres1", "gtinfoil", "hiker", "mime", "momchar1", "musicshirt1", "musicshirt2", "nw_gshirt02", "realitygirl", "sears1", "shirtvest1", "shirtvest2", "sponsorCityGirl", "srgirl", "tourist", "tt_boy", "wwcowgirl"];

		
		
		
		
		
		
		
		
		
		
		
		
		
		
	}
}
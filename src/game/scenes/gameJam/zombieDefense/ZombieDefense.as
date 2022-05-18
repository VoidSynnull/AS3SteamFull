package game.scenes.gameJam.zombieDefense
{
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.text.TextField;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.data.display.SharedBitmapData;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.collider.HazardCollider;
	import game.components.hit.Hazard;
	import game.components.hit.ValidHit;
	import game.creators.ui.ToolTipCreator;
	import game.data.animation.entity.character.Attack;
	import game.data.animation.entity.character.Dizzy;
	import game.data.animation.entity.character.FistPunch;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Place;
	import game.data.character.LookData;
	import game.data.text.TextStyleData;
	import game.managers.EntityPool;
	import game.scene.template.CharacterGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.gameJam.zombieDefense.components.DefenseTrap;
	import game.scenes.gameJam.zombieDefense.components.DefenseZombie;
	import game.scenes.gameJam.zombieDefense.systems.DefenseTrapSystem;
	import game.scenes.gameJam.zombieDefense.systems.DefenseZombieSystem;
	import game.ui.elements.ConfirmationDialogBox;
	import game.util.ArrayUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DataUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TextUtils;
	import game.util.TweenUtils;
	
	public class ZombieDefense extends PlatformerGameScene
	{
		private var _levels:Array;
		private var _currLevel:int = 0;
		private var _currWave:int = 0;
		private var _activeZombies:int=0;
		
		private const _prepTime:int = 20;
		private const playerHealthMax:int = 10;
		
		private var playerHealth:int = playerHealthMax;
		
		private var healthBar:Entity;
		private var textBox:Entity;
		
		private var _path:Array;
		private var spawnDelay:Number = 1.0;
		
		private var _entityPool:EntityPool;	
		
		private var _characterGroup:CharacterGroup;
		
		private var _defenses:Array;
		private var buttonBearTrap:Entity;
		private var buttonFist:Entity;
		private var buttonIce:Entity;
		private var buttonOilBucket:Entity;
		private var buttonOil:Entity;
		private var arrowButton:Entity;
		
		private const MAX_ZOMBIES:uint = 12;
		private const MAX_DEFENSES:uint = 12;
		// pool id's
		private const POOL_ZOM:String = "zombie";
		private const POOL_DEF:String = "defense";
		
		private var _zombieSkinColors:Vector.<Number> = new<Number>[0X66CCFF, 0x32B6D7, 0x606A9F, 0x43316B];
		private var _zombieHairColors:Vector.<Number> = new<Number>[0x3378CF, 0x335FB7, 0x3C3F86, 0x371554];
		
		public const facialBoy:Array 	= ["empty", "empty", "empty", "empty", 2, "bl_drem", "mk_writer", "mk_disgruntled_programmer", "nateg", "realityteen", "ss"];
		public const facialGirl:Array 	= ["empty", "empty", "empty", "empty", 2, 4, "bl_drem", "bl_critic02", "curator", "librarian", "mk_cutter", "nateg", "realityteen", "sponsor_LM_Stella", "ss"];
		
		public const hairBoy:Array 		= [1, 6, 7, 9, 10, 22, 26, 34, 35, 36, 44, "prisoner1", "z_disco2", "gasDude", "gulliver", "lc_slayton", "mc_loverboy", "nateg", "realityteen", "referee", "SRishmael", "tourguide", "VCgothBoy", "wwprisoner"];
		public const hairGirl:Array		= [1, 23, 27, 29, 32, 39, 40, 43, "z_disco4", "bl_barf", "curator", "girlhair4", "girlhair5", "girlhair6", "mikesmarket", "mtdancer", "mthtownie02", "mythbeach2", "sears1", "sears2", "sears3", "soccer", "sponsorAuntOpal", "sponsorfarmgirl", "SRishmael", "srmom", "srstubb", "srstarbuck", "VCgothGirl", "z_disco3"];
		
		public const pantsBoy:Array 	= [1, 2, 3, 6, 10, "z_dancer1", "wwannouncer", "adams", "astroalien1", "astroalien3", "astrofarmer", "astroking", "astrogossip3", "astroguard1", "astrozone", "conworker1", "eiffel", "finvendor", "mc_junior"];
		public const pantsGirl:Array 	= [1, 2, 3, 4, 8, 9, 10, 12, 14, "adams", "astroalien1", "astroalien2", "astroalien4", "astroguard1", "astrozone", "balloonpilate01", "bl_cashier", "buckyfan", "conworker1", "directord", "girlskirt1", "girlskirt2", "girlskirt3", "girlskirt4", "girlskirt5", "mc_junior", "sponsorMargo"];
		
		public const shirtBoy:Array 	= ["z_dancer1", "z_disco2", 1, 4, 5, 11, 13, 21, 22, 26, "balloonpilot02", "biker", "bl_cashier", "bl_dref", "bl_drem", "bluetie", "boyshirt1", "counterres1", "counterres2", "edworker1", "gtinfoil", "hashimoto", "hiker", "lc_boy", "mikesmarket", "mime", "nw_burg", "nim2", "patron1", "realityboy", "sears4", "tourist", "wwman"];
		public const shirtGirl:Array	= ["z_disco3", "z_disco4", 2, 3, 4, 5, 7, 9, 10, 11, 12, 19, 23, 25, 26, "balloonpilot02", "biker", "bl_mom02", "bl_sofia", "counterres1", "gtinfoil", "hiker", "mime", "momchar1", "musicshirt1", "musicshirt2", "nw_gshirt02", "realitygirl", "sears1", "shirtvest1", "shirtvest2", "sponsorCityGirl", "srgirl", "tourist", "tt_boy", "wwcowgirl"];
		private var menuEntity:Entity;
		
		public function ZombieDefense()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/gameJam/zombieDefense/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{		
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			setupGame();
			//SceneUtil.delay(this,0.5,Command.create(this.addChildGroup,new ZombieDefensePopup(overlayContainer)));
			super.loaded();
		}
		
		private function setupGame():void
		{
			_entityPool = new EntityPool();
			
			_characterGroup = getGroupById(CharacterGroup.GROUP_ID) as CharacterGroup; 
			
			parseLevels();
			
			setupMap();
			
			setUpZombies();
			
			setupDefenses();
			
			// setup phase begins, wave soon
			startDefenseSetup();
		}
		
		private function setupMap():void
		{
			// set up player and path for zombies
			_path = new Array();
			for (var i:int = 0; null != _hitContainer["path"+i]; i++) 
			{
				_path.push(new Point(_hitContainer["path"+i].x,_hitContainer["path"+i].y));
			}
			trace("PATH LOADED:: "+_path);
			
			// setup health ui
			var clip:MovieClip = _hitContainer["healthBar"];
			overlayContainer.addChild(clip);
			clip.x = (shellApi.viewportWidth/2) - (clip.width/2);
			clip.y = clip.height;
			var healthParent:Entity = EntityUtils.createSpatialEntity(this,clip);
			clip = clip["bar"];
			healthBar = EntityUtils.createSpatialEntity(this, clip);
			EntityUtils.addParentChild(healthBar,healthParent);
			// output text for ui
			textBox = makeTextField(healthParent," ",null,800,100,"text",null,50);
			// player can pass down thru floors, zombies can't
			var ignoreHits:ValidHit = new ValidHit("zomFloor");
			ignoreHits.inverse = true;
			player.add(ignoreHits);
			player.remove(HazardCollider);
		}
		
		private function updatePlayerHealth(change:int = 0):void
		{
			//trace("healthUpdate:"+playerHealth);
			if(change == 0){
				updateTextBox("health");
			}
			else if(change < 0){
				CharUtils.setAnim(player, Grief);
				// sound
			}
			playerHealth += change;
			var delta:Number = playerHealth/playerHealthMax;
			TweenUtils.entityTo( healthBar, Spatial, 0.25, {scaleX:delta});
			if(playerHealth <= 0){
				//you dead! zombify player
				SkinUtils.setSkinPart( player, SkinUtils.SKIN_COLOR, _zombieSkinColors[0], false );
				SkinUtils.setSkinPart( player, SkinUtils.HAIR_COLOR, _zombieHairColors[0], false );
				SkinUtils.setSkinPart( player, SkinUtils.MARKS, "z_zombie", false);
				SkinUtils.setSkinPart( player, SkinUtils.EYE_STATE, "zombie", false);
				SkinUtils.setSkinPart( player, SkinUtils.MOUTH, "z_zombie", false);
				CharUtils.setAnim(player, Dizzy);
				SceneUtil.delay(this,3.0,showGameover);
				SceneUtil.lockInput(this, true);
			}
		}
		
		private function updateTextBox(barText:String):void
		{
			//trace("updateTextBox: "+barText);
			var lvlWave:String = "Lvl:" + (_currLevel+1) + ", Wave:" + (_currWave+1) + " ";
			TextField(EntityUtils.getDisplay(textBox).displayObject).text = lvlWave + barText;
		}
		
		private function showGameover(win:Boolean = true):void
		{
			var text:String;
			if(!win){
				text = "The zomberries got you! Try again?";
			}
			else{
				text = "You escaped the zomberry horde! Want to play again?";
			}
			var popup:ConfirmationDialogBox = this.addChildGroup(new ConfirmationDialogBox(2,text,restartGame,closeGame)) as ConfirmationDialogBox;
			popup.darkenBackground = true;
			popup.init( overlayContainer );
		}
		
		private function closeGame():void
		{
			//shellApi.loadScene(ZombieDefense);
		}
		
		private function restartGame():void
		{
			shellApi.loadScene(ZombieDefense);
		}		
		
		private function parseLevels():void
		{
			// levels contain array of levels contianing waves of zombies
			_levels = new Array();
			var levelXml:XML = super.getData( "levels.xml" );
			var lvlsList:XMLList = levelXml.level;
			for (var i:int = 0; i < lvlsList.length(); i++) 
			{
				var waves:XMLList = lvlsList[i].wave;
				var level:Array = new Array();
				for (var j:int = 0; j < waves.length(); j++) 
				{
					level.push(DataUtils.getArray(waves[j]));
				}
				_levels.push( level );
			}
		}
		
		private function setUpZombies():void
		{
			this.addSystem(new DefenseZombieSystem());
			this.addSystem(new DefenseTrapSystem());
			_entityPool.setSize(POOL_ZOM, MAX_ZOMBIES);
			var zombie:Entity;
			for(var i:int = 0 ; i < MAX_ZOMBIES; i++)
			{
				// throw zombie char load to the wind and hope for the best
				zombie = _characterGroup.createNpc("zombie"+i,getZombieLookData(),836,576,"right","",null,zombieCreated);
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
			// put to pool
			_entityPool.release(zombieEntity, POOL_ZOM);
			
			zombieEntity.add( new Sleep( true, true ) );
			EntityUtils.visible(zombieEntity, false);
			zombieEntity.add(new Motion());
			
			var zom:DefenseZombie = new DefenseZombie(0);
			zom.stateChanged.add(zombieStateChanged);
			zombieEntity.add(zom);
			
			// lock zombie parts
			SkinUtils.getSkinPart( zombieEntity, SkinUtils.MOUTH ).lock = true;
			// remove interactions
			EntityUtils.removeInteraction( zombieEntity );
		}
		
		private function makeZombie(health:int = 1, path:Array = null):Entity
		{
			var zombieEntity:Entity = _entityPool.request(POOL_ZOM);
			if(zombieEntity){				
				// set health and put into play
				var zom:DefenseZombie = zombieEntity.get(DefenseZombie);
				zom.health = health;
				zom.path = path;
				zom.pathIndex = 0;
				zom.active = true;
				zombieEntity.add( new Sleep( false, true ) );
				EntityUtils.visible(zombieEntity, true);
				Display(zombieEntity.get(Display)).alpha = 1.0;
				var pt:Point = zom.path[zom.pathIndex];
				EntityUtils.position(zombieEntity, pt.x, pt.y);
				pt = zom.getNextPathPt();
				CharUtils.moveToTarget(zombieEntity, pt.x, pt.y, false, pathPtReached);
				// cap speed
				CharacterMotionControl(zombieEntity.get(CharacterMotionControl)).maxAirVelocityX = 300;
				CharacterMotionControl(zombieEntity.get(CharacterMotionControl)).maxVelocityX = 200;
				CharacterMotionControl(zombieEntity.get(CharacterMotionControl)).maxVelocityY = 300;
				// colors!
				SkinUtils.setSkinPart( zombieEntity, SkinUtils.SKIN_COLOR, _zombieSkinColors[health-1], false );
				SkinUtils.setSkinPart( zombieEntity, SkinUtils.HAIR_COLOR, _zombieHairColors[health-1], false );
			}
			return zombieEntity;
		}
		
		private function pathPtReached(zombieEntity:Entity):void
		{
			var zom:DefenseZombie = zombieEntity.get(DefenseZombie);
			var pt:Point = zom.getNextPathPt();
			if(pt){
				if(zom.health > 0){
					CharUtils.moveToTarget(zombieEntity, pt.x, pt.y, false, pathPtReached);
				}
				else{
					// dead, do nothing here
					//cureZombie(zombieEntity);
				}
			}
			else{
				// reached end, hurt player!
				zombieAttack(zombieEntity, true);
			}
		}
		
		private function zombieAttack(zombieEntity:Entity, remove:Boolean = true):void
		{
			// attack player, remove zombie
			CharUtils.setAnim(zombieEntity, Attack);
			TweenUtils.entityTo( zombieEntity, Display, .6, {alpha:0, ease:Sine.easeIn})
			SceneUtil.delay( this, 0.6, Command.create(zombieFaded, zombieEntity) );
			updatePlayerHealth(-1);
		}
		
		
		private function zombieStateChanged(zombieEntity:Entity, state:String):void
		{
			var zom:DefenseZombie = zombieEntity.get(DefenseZombie);
			switch(state)
			{
				case DefenseZombieSystem.REACHED:
				{
					//reached target 
					//updatePlayerHealth(-1);
					break;
				}
				case DefenseZombieSystem.HIT:
				{
					//reached target 
					if(zom.health>0){
						SkinUtils.setSkinPart( zombieEntity, SkinUtils.SKIN_COLOR, _zombieSkinColors[zom.health-1], false );
						SkinUtils.setSkinPart( zombieEntity, SkinUtils.HAIR_COLOR, _zombieHairColors[zom.health-1], false );
					}
					break;
				}
				case DefenseZombieSystem.DEAD:
				{
					cureZombie(zombieEntity);
					break;
				}
				case DefenseZombieSystem.RECOVER:
				{
					recoverZombie(zombieEntity);
					break;
				}
			}
		}
		
		private function recoverZombie(zombieEntity:Entity):void
		{
			// return wayawrd zombie to the path of rightness
			var zom:DefenseZombie = zombieEntity.get(DefenseZombie);
			var pt:Point = zom.path[zom.pathIndex];
			EntityUtils.position(zombieEntity, pt.x, pt.y);
			pt = zom.path[zom.pathIndex];
			CharUtils.moveToTarget(zombieEntity, pt.x, pt.y, false,pathPtReached);
		}
		
		private function cureZombie(zombieEntity:Entity):void
		{
			MotionUtils.zeroMotion(zombieEntity);
			var zom:DefenseZombie = zombieEntity.get(DefenseZombie);
			zom.active = false;
			SkinUtils.setRandomSkinColors( zombieEntity );
			SkinUtils.setSkinPart( zombieEntity, SkinUtils.EYES, "eyes");
			CharUtils.setAnim(zombieEntity, FistPunch);
			
			TweenUtils.entityTo( zombieEntity, Display, .6, {alpha:0, ease:Sine.easeIn})
			SceneUtil.delay( this, .6, Command.create(zombieFaded, zombieEntity) );
		}
		
		private function zombieFaded( zombieEntity:Entity ):void
		{
			_activeZombies--;
			trace("zombiesRemaining:"+_activeZombies);
			if(_activeZombies <= 0){
				// wave or level over, launch next
				if(_currWave < _levels[_currLevel].length-1){
					// next wave
					_currWave++;
					SceneUtil.delay(this, 1.5, Command.create(tickTimer,_prepTime,startWave));
				}
				else if(_currLevel < _levels.length-1){
					// next level
					_currLevel++;
					_currWave = 0;
					SceneUtil.delay(this, 1.5, Command.create(tickTimer,_prepTime,startWave));
				}
				else{		
					// beat the game!
					SceneUtil.delay(this, 1.5, Command.create(showGameover,true));
				}
			}
			EntityUtils.getDisplay(zombieEntity).alpha = 1;
			EntityUtils.visible(zombieEntity,false,true);
			(zombieEntity.get(Sleep) as Sleep).sleeping = true;
			EntityUtils.position(zombieEntity, -200, -200);
			_entityPool.release(zombieEntity,POOL_ZOM);
		}
		
		private function setupDefenses():void
		{		
			// add menu to overlay
			var bgClip:MovieClip = _hitContainer["buildMenu"];
			bgClip.mouseEnabled = true;
			bgClip.mouseChildren = true;
			menuEntity  = EntityUtils.createSpatialEntity(this, bgClip, overlayContainer);
			// make defense spawn buttons
			buttonBearTrap = addTrapButton(bgClip,"bearTrapButton");
			buttonFist = addTrapButton(bgClip,"fistTrapButton");
			buttonIce = addTrapButton(bgClip,"iceTrapButton");
			buttonOilBucket = addTrapButton(bgClip,"bucketTrapButton");
			buttonOil = addTrapButton(bgClip,"oilTrapButton");
			
			arrowButton = EntityUtils.createSpatialEntity(this, bgClip["arrow"]);
			var inter:Interaction = InteractionCreator.addToEntity(arrowButton,[InteractionCreator.CLICK]);
			inter.click.add(toggleBuildMenu);
			ToolTipCreator.addToEntity(arrowButton);
			
			_defenses = new Array();
		}
		
		private function toggleBuildMenu(...p):void
		{
			var targ:Number = -64;
			if(menuEntity.get(Spatial).x < 0){
				targ = 80;
			}
			TweenUtils.entityTo(menuEntity, Spatial, 0.4, {x:targ});
		}
		
		private function addTrapButton(bgClip:MovieClip,name:String):Entity
		{
			var trapButton:Entity = EntityUtils.createSpatialEntity(this, bgClip[name], bgClip);
			trapButton.add(new Id(name));
			var inter:Interaction = InteractionCreator.addToEntity(trapButton,[InteractionCreator.CLICK]);
			inter.click.add(beginPlaceTrap);
			ToolTipCreator.addToEntity(trapButton);
			return trapButton;
		}		
		
		private function beginPlaceTrap(trap:Entity):void
		{
			// lock and chill for a moment, then add trap
			SceneUtil.lockInput(this,true);
			SceneUtil.delay(this, 0.3, Command.create(placeTrap,trap));
		}
		
		private function placeTrap(trapButton:Entity):void
		{
			// place trap at player's location
			CharUtils.setAnim(player, Place);
			var targetPos:Point = EntityUtils.getPosition(player); 
			var type:String = trapButton.get(Id).id;
			var hazard:Hazard = getEntityById("hazardDummy").get(Hazard);
			// make trap comp
			var trap:DefenseTrap = new DefenseTrap();
			// get proper art and clone it
			var trapArt:Sprite;
			var bitData:SharedBitmapData;
			var asset:MovieClip;
			switch(type)
			{
				case "bearTrapButton":
				{
					asset = _hitContainer["bearTrap"];
					type = "bearTrap"+_defenses.length;
					trap.damage = 1;
					trap.effect = DefenseTrap.NONE;
					trap.rearmTime = 1.0;
					trap.effectDuration = 0;
					targetPos.y += player.get(Spatial).height/3.5;
					break;
				}
				case "fistTrapButton":
				{
					asset = _hitContainer["fistTrap"];
					type = "fistTrap"+_defenses.length;
					trap.damage = 1;
					trap.effect = DefenseTrap.KNOCKBACK;
					trap.rearmTime = 3.0;
					trap.effectDuration = 0.4;
					targetPos.y += 0;
					break;
				}		
				case "iceTrapButton":
				{
					asset = _hitContainer["iceTrap"];
					type = "iceTrap"+_defenses.length;
					trap.damage = 1;
					trap.effect = DefenseTrap.STUN;
					trap.rearmTime = 5.0;
					trap.effectDuration = 2.0;
					targetPos.y -= 0;
					break;
				}
				case "bucketTrapButton":
				{
					asset = _hitContainer["bucketTrap"];
					type = "bucketTrap"+_defenses.length;
					trap.damage = 1;
					trap.effect = DefenseTrap.SLOW;
					trap.rearmTime = 2.5;
					trap.effectDuration = 1.5;
					targetPos.y -= 20;
					break;
				}
				case "oilTrapButton":
				{
					asset = _hitContainer["oilTrap"];
					type = "oilTrap"+_defenses.length;
					trap.damage = 1;
					trap.effect = DefenseTrap.SLOW;
					trap.rearmTime = 1.5;
					trap.effectDuration = 1.0;
					targetPos.y += player.get(Spatial).height/3;
					break;
				}
			}
			bitData = BitmapUtils.createBitmapData(asset, 1);
			trapArt = BitmapUtils.createBitmapSprite(asset, 1, null, true, 0, bitData);
			var trapEnt:Entity = EntityUtils.createMovingEntity(this,trapArt, _hitContainer);
			_defenses.push(trapEnt);
			EntityUtils.position(trapEnt, targetPos.x, targetPos.y);
			Display(trapEnt.get(Display)).isStatic = false;
			Display(trapEnt.get(Display)).visible = true;
			trapEnt.add(new Id(type));
			trapEnt.add(trap);
			// resume player
			SceneUtil.lockInput(this, false);
		}
		
		private function startDefenseSetup():void
		{
			playerHealth = playerHealthMax;
			tickTimer(_prepTime, startWave);
		}
		
		private function updateTimerBar(time:Number, callback:Function = null):void
		{
			updateTextBox("Prep Time");
			var delta:Number = time/_prepTime;
			TweenUtils.entityTo( healthBar, Spatial, 0.25, {scaleX:delta, onComplete:callback});
		}	
		
		private function tickTimer(time:int, onComplete:Function):void
		{
			if(time > 0){
				// tick by seconds
				// display time
				updateTimerBar(time);
				SceneUtil.delay(this, 1.0, Command.create(tickTimer,time-1, onComplete));
			}else{
				// time's up trigger
				updateTimerBar(time, onComplete);
			}
		}
		
		private function startWave():void
		{
			updatePlayerHealth(0);
			// spawn zombies from wave one at a time until end of wave, next wave begins when curr is dead
			var wave:Array = _levels[_currLevel][_currWave];
			var zombieEntity:Entity;
			for (var i:int = 0; i < wave.length; i++)
			{
				SceneUtil.delay(this, spawnDelay * i, Command.create(makeZombie,wave[i],_path));
			}
			// decrement this when zombie leaves play
			_activeZombies = wave.length;
		}
		
		private function waveComplete():void
		{
			
		}
		
		private function levelComplete():void
		{
			
		}
		
		private function makeTextField(parent:Entity, text:String, styleId:String, width:Number = 80, height:Number = 100, tfName:String = "tf", offset:Point = null, size:int = 52):Entity
		{		
			var parentDisplay:MovieClip = Display(parent.get(Display)).displayObject;
			var textfield:TextField = parentDisplay[tfName];
			//change the font style
			if(styleId != null){
				var styleData:TextStyleData = shellApi.textManager.getStyleData( TextStyleData.UI, styleId);	
				styleData.size = size;
				TextUtils.applyStyle(styleData,textfield);
			}
			textfield.alwaysShowSelection = false;
			textfield.selectable = false;
			
			textfield.text = text;
			if(width){
				textfield.width = width;
			}
			if(height){
				textfield.height = height;
			}
			textfield.embedFonts = true;
			if(offset){
				textfield.x += offset.x;
				textfield.y += offset.y;
			}
			var tfEntity:Entity = EntityUtils.createSpatialEntity(this, textfield, parentDisplay);			
			return tfEntity;
		}
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
	}
}
package game.scenes.carnival.midwayNight{
	import com.greensock.easing.Linear;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionTarget;
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.entity.character.Talk;
	import game.components.scene.SceneInteraction;
	import game.components.hit.Zone;
	import game.creators.animation.FSMStateCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.scene.HitCreator;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Tremble;
	import game.scenes.carnival.CarnivalEvents;
	import game.data.scene.hit.HazardHitData;
	import game.data.scene.hit.HitType;
	import game.data.sound.SoundModifier;
	import game.data.ui.ToolTipType;
	import game.scene.template.CharacterGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.carnival.balloonPop.BalloonPop;
	import game.scenes.carnival.mirrorMaze.MirrorMaze;
	import game.scenes.carnival.ringmastersTent.RingmastersTent;
	import game.scenes.carnival.shared.popups.duckGame.DuckGamePopup;
	import game.scenes.carnival.shared.states.MonsterAttackState;
	import game.scenes.carnival.shared.states.MonsterHitRetreatState;
	import game.scenes.carnival.shared.states.MonsterRetreatState;
	import game.scenes.carnival.shared.states.MonsterStandState;
	import game.scenes.carnival.shared.states.MonsterStompState;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.TalkAction;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	import org.osflash.signals.Signal;
	
	public class MidwayNight extends PlatformerGameScene
	{
		
		private var _events:CarnivalEvents;
		private var _edgar:Entity;
		private var _guesser:Entity;
		private var _foodie:Entity;
		private var _duckworker:Entity;
		private var _ringmaster:Entity;
		private var _ralph:Entity;
		private var _garbage_mc:Entity;
		private var _duckies:Entity;
		private var timeline:Timeline;
		private var _monsterZoneEntity:Entity;
		private var _monsterZone2Entity:Entity;		
		private var _bubbleEntity:Entity;
		//private var _cottonCandy:Entity;
		private var monsterZone:Zone;
		private var _scared:Boolean = false;
		private var _havebubbles:Boolean = false;
		private var _crawling:Boolean = false;
		private var _wait:Boolean = false;
		
		private var bubbleSoundEntity:Entity;
		private var bubbleAudio:Audio;		

		
		public function MidwayNight()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carnival/midwayNight/";
			//super.showHits = true;
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
			super.loaded();
			
			super.shellApi.eventTriggered.add(handleEventTriggered);
			
			_edgar = super.getEntityById("edgar");
			_ringmaster = super.getEntityById("ringmaster");
			_ralph = super.getEntityById("ralph");
			
			_duckies = EntityUtils.createSpatialEntity( this, MovieClip( MovieClip(super._hitContainer).duckpond ) );	
			//_cottonCandy = EntityUtils.createSpatialEntity( this, MovieClip( MovieClip(super._hitContainer).candy_btn ) );	
			
			_garbage_mc = EntityUtils.createSpatialEntity( this, MovieClip( MovieClip(super._hitContainer).garbage_mc ) );
			TimelineUtils.convertClip( MovieClip( MovieClip(super._hitContainer).garbage_mc ), this, _garbage_mc, null, false );
			Timeline(_garbage_mc.get(Timeline)).gotoAndStop(1);	
			
			_duckworker = EntityUtils.createSpatialEntity( this, MovieClip( MovieClip(super._hitContainer).duckgameworker ) );
			TimelineUtils.convertClip( MovieClip( MovieClip(super._hitContainer).duckgameworker ), this, _duckworker, null, false );
			Timeline(_duckworker.get(Timeline)).gotoAndStop("off");	
			_duckworker.get(Timeline).handleLabel( "idleLoop", loopDuck, false  );
			_duckworker.get(Timeline).handleLabel( "croakend", scarePlayer, false );			
			_duckworker.get(Timeline).handleLabel( "tremble", playerShake, false );
			_duckworker.get(Timeline).handleLabel( "yell", croakSound, false );
			_duckworker.get(Timeline).handleLabel( "splash", splashSound, false );
			
			_foodie = EntityUtils.createSpatialEntity( this, MovieClip( MovieClip(super._hitContainer).foodstandworker ) );
			TimelineUtils.convertClip( MovieClip( MovieClip(super._hitContainer).foodstandworker ), this, _foodie, null, false );			
			_foodie.get(Timeline).handleLabel( "boredLoop", loopFoodie, false );
			_foodie.get(Timeline).handleLabel( "end", boredFoodie, false );
			//_foodie.get(Timeline).handleLabel( "deflate", fartSound, false );
			Timeline(_foodie.get(Timeline)).gotoAndPlay("bored");

			ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).foodie_btn, this, handleFoodieButtonClicked, null, null, ToolTipType.CLICK);
			
			if (this.shellApi.checkEvent(_events.ESCAPED_RINGMASTER_TENT))
			{
				super.shellApi.camera.target = _ringmaster.get(Spatial);
				player.get(Spatial).x = 4378;
				player.get(Spatial).y = 1825;
				lockControl();
				
				var path:Vector.<Point> = new Vector.<Point>();
				
				path.push(new Point(1515, 1412));
				path.push(new Point(1395, 1270));
				CharUtils.followPath(_ringmaster, path, charFollow, true, false);
				super.removeEntity( _edgar );
				super.removeEntity( _ralph );
			}else
			{	
				
				_guesser = EntityUtils.createSpatialEntity( this, MovieClip( MovieClip(super._hitContainer).weightguesser ) );
				_guesser.add(new Talk());
				_guesser.add( new Id( "guesser" ));
				CharUtils.assignDialog(_guesser, this, 'guesser',false,-.05,.5);
				
				
				ToolTipCreator.addUIRollover( _guesser, "click" );				
				InteractionCreator.addToEntity( _guesser, [ InteractionCreator.CLICK ]);
				var guesserInteraction:SceneInteraction = new SceneInteraction();
				guesserInteraction.offsetX = -200;
				guesserInteraction.reached.removeAll();
				guesserInteraction.reached.add(guesserClicked);				
				_guesser.add( guesserInteraction )
					
				var edgarInteraction:SceneInteraction = _edgar.get(SceneInteraction);
				edgarInteraction.reached.removeAll();
				edgarInteraction.reached.add(edgarClicked);

				ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).pool_btn, this, handlePoolButtonClicked, null, null, ToolTipType.CLICK);
			
				//if (!super.shellApi.checkItem(_events.COTTON_CANDY) && !this.shellApi.checkEvent(_events.USED_COTTON_CANDY)){
					//ButtonCreator.assignButtonEntity(_cottonCandy,MovieClip(super._hitContainer).candy_btn,this,handleCandyButtonClicked, null, null, ToolTipType.CLICK);
				//}else{
					//removeEntity(_cottonCandy);
				//}
				
				ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).garbage_btn, this, handleGarbageButtonClicked, null, null, ToolTipType.CLICK);
				
				if (super.shellApi.checkHasItem(_events.SHARPENED_DART)|| super.shellApi.checkHasItem(_events.BLUNTED_DART)){
					ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).dart_btn, this, handleDartButtonClicked, null, null, ToolTipType.CLICK);
				}								
				
				super.removeEntity( _ringmaster );
				
				if (!super.shellApi.checkHasItem(_events.BLACK_LIGHTBULB)){				
					
					_monsterZoneEntity = super.getEntityById( "monsterZone" );
					
					monsterZone = _monsterZoneEntity.get( Zone );
					monsterZone.pointHit = true;
					monsterZone.entered.add(doMonsterJump);
					
					if (!this.shellApi.checkEvent(_events.SAW_DUCK_MONSTER)){					
						setUpBubbles();
					}else{
						SceneUtil.addTimedEvent( this, new TimedEvent( randomRange(5 , 20), 1, makeBubbles ));
					}
				}				
				
				if (this.shellApi.checkEvent(_events.SPOKE_EDGAR_FORMULA) && !this.shellApi.checkEvent(_events.EDGAR_RAN_TENT)){
					_edgar.get(Spatial).x = 5160;
					_edgar.get(Spatial).y = 1950;					
					
					super.shellApi.camera.target = _edgar.get(Spatial);
					var pathEd:Vector.<Point> = new Vector.<Point>();
					
					pathEd.push(new Point(4530, 1950));
					pathEd.push(new Point(4380, 1730));
					CharUtils.followPath(_edgar, pathEd, finishEdgarTent, true, false);	
					lockControl();
				}else if (this.shellApi.checkEvent(_events.EDGAR_RAN_TENT) &&  !super.shellApi.checkHasItem(_events.SODIUM_THIOPENTAL)){
					super.removeEntity( _edgar );
				}
				
				setupRalphMonster();
			}
		}
		
		private function finishEdgarTent(...args):void{
			super.removeEntity( _edgar );
			super.shellApi.triggerEvent(_events.EDGAR_RAN_TENT, true)
			super.shellApi.camera.target = super.shellApi.player.get(Spatial);		
			restoreControl();
		}
		
		private function makeBubbles(...args):void
		{
			if (_scared != true  && _crawling != true){				
				setUpBubbles();
				SceneUtil.addTimedEvent( this, new TimedEvent( randomRange(10, 20), 1, removeBubbles ));
			}
		}
		
		private function removeBubbles(...args):void
		{
			super.removeEntity( _bubbleEntity );					
			TweenUtils.entityTo(_duckies, Spatial, .5,{y:1569, ease:Linear.easeIn}, '', 1);
			bubbleAudio.stop(SoundManager.EFFECTS_PATH + "dissolve_bubbling_01.mp3");
			_havebubbles = false;	
			if (_scared != true  && _crawling != true){
				SceneUtil.addTimedEvent( this, new TimedEvent( randomRange(5 , 20), 1, makeBubbles ));
			}
		}
		
		
		private function setUpBubbles(...args):void
		{
			var bubbles:Bubbles = new Bubbles();
			var clip:MovieClip = MovieClip(super._hitContainer).bubbles;
			clip.visible = false;
			bubbles.init(clip.getRect(super._hitContainer),new Point(-5,-25),new Point(.5,3),10,1,1,.3,-25);
			_bubbleEntity = EmitterCreator.create(this,_hitContainer,bubbles,0,0,null,"bubbles");
			_havebubbles = true;			
			TweenUtils.entityTo(_duckies, Spatial, .5,{y:1600, ease:Linear.easeIn});
			
			bubbleSoundEntity = new Entity();
			bubbleAudio = new Audio();
			bubbleAudio.play(SoundManager.EFFECTS_PATH + "dissolve_bubbling_01.mp3", true, [SoundModifier.POSITION, SoundModifier.EFFECTS]);
			bubbleSoundEntity.add(bubbleAudio);
			bubbleSoundEntity.add(new Spatial(330, 1569));
			bubbleSoundEntity.add(new AudioRange(400, 1, 1));
			bubbleSoundEntity.add(new Id("soundSource"));
			super.addEntity(bubbleSoundEntity);
		}
		
		private function doMonsterJump(...args):void{
			if (!this.shellApi.checkEvent(_events.SAW_DUCK_MONSTER) || _havebubbles){
				_crawling = true;	
				monsterZone.entered.remove(doMonsterJump);
				Timeline(_duckworker.get(Timeline)).gotoAndPlay("appear");				
				CharUtils.setAnim(player, Tremble);
				CharUtils.setDirection(player, false);
				removeBubbles();
				//lockControl();
				MotionUtils.zeroMotion(super.player, "x");
				MotionUtils.zeroMotion(super.player, "y");
				player.get(Spatial).y = 1910;
				player.get(Spatial).rotation = 0;
			}
		}
		
		private function playerShake(...args):void{			
			CharUtils.setAnim(player, Grief);
		}
		
		private function splashSound(...args):void{		
			super.shellApi.triggerEvent("waterSplash");
		}
		
		private function croakSound(...args):void{	
			super.shellApi.triggerEvent("yell");
		}
		
		//private function fartSound(...args):void{	
			//super.shellApi.triggerEvent("deflate");
		//}
		
		private function scarePlayer(...args):void{
			
			if (_scared == false){
				CharUtils.stateDrivenOn(player, false);
				CharUtils.moveToTarget(player, 1800, 1950, false, restoreControl);
			
				var monsterZone2:Zone;
				_monsterZone2Entity = super.getEntityById( "monsterZone2" );			
				monsterZone2 = _monsterZoneEntity.get( Zone );
				monsterZone2.pointHit = true;
				monsterZone2.entered.add(scareAgain);
				_scared = true;
				super.shellApi.triggerEvent( _events.SAW_DUCK_MONSTER, true );
			}else{
				var xpos:Number = player.get(Spatial).x;
				var dir:Number = player.get(Spatial).scaleX;
				if (dir < 0) dir = 1; else dir = -1;				
				var newX:Number = xpos+(700*dir);

				CharUtils.stateDrivenOn(player, false);
				CharUtils.moveToTarget(player, newX, 1950, false, restoreControl);
			}
			
		}
		
		private function scareAgain (...args):void{
			MotionUtils.zeroMotion(super.player, "x");
			MotionUtils.zeroMotion(super.player, "y");
			player.get(Spatial).y = 1910;
			player.get(Spatial).rotation = 0;
			//SceneUtil.lockInput(this, true);
			Timeline(_duckworker.get(Timeline)).gotoAndPlay("croack");
			CharUtils.setAnim(player, Grief);
		}

		private function loopFoodie(...args):void{
			Timeline(_foodie.get(Timeline)).gotoAndPlay("bored");	
		}
		
		private function boredFoodie(...args):void{
			Timeline(_foodie.get(Timeline)).gotoAndPlay("bored");	
			//restoreControl();
		}
		
		private function handleFoodieButtonClicked(entity:Entity):void	
		{
			Timeline(_foodie.get(Timeline)).gotoAndPlay("excited");
			super.shellApi.triggerEvent("jelly");
			//lockControl();
		}
		
		private function loopDuck(...args):void{
			Timeline(_duckworker.get(Timeline)).gotoAndPlay("idle");	
		}
		
		private function charFollow(...args):void{
			
			super.removeEntity( _ringmaster );
			super.shellApi.camera.target = super.shellApi.player.get(Spatial);
			var path:Vector.<Point> = new Vector.<Point>();
			
			path.push(new Point( 1980, 1950 ) );
			path.push(new Point( 2000, 1670 ) );
			path.push(new Point( 2180, 1510 ) );
			path.push(new Point( 2000, 1400 ) );
			path.push(new Point( 1515, 1412 ) );
			path.push(new Point( 1395, 1270 ) );
			
			CharUtils.followPath(player, path, pathComplete, true, false);
			
		}
		
		private function pathComplete(entity:Entity):void
		{
			this.shellApi.loadScene(MirrorMaze);
		}
		
		private function handleDartButtonClicked(entity:Entity):void 
		{						
			this.shellApi.loadScene(BalloonPop);
		} 
		
		private function handlePoolButtonClicked(entity:Entity):void	
		{
			var duckGamePopup:DuckGamePopup = super.addChildGroup( new DuckGamePopup( super.overlayContainer )) as DuckGamePopup;
		}
		
		//private function handleCandyButtonClicked(entity:Entity):void	
		//{
			//super.shellApi.getItem(_events.COTTON_CANDY, null, true);
			//removeEntity(_cottonCandy);
			
		//}
		
		private function guesserClicked(...args):void{
			if (super.shellApi.checkHasItem(_events.SODIUM_THIOPENTAL)){
				Dialog(_guesser.get(Dialog)).sayById("hypnotizePowder");	
			}else if(super.shellApi.checkHasItem(_events.FORMULA)){
				Dialog(_guesser.get(Dialog)).sayById("hypnotizeFormula");
			}else if(super.shellApi.checkHasItem(_events.BLACK_LIGHTBULB)){
				Dialog(_guesser.get(Dialog)).sayById("haveBlacklight");
			}else if(super.shellApi.checkHasItem(_events.SECRET_MESSAGE)){
				Dialog(_guesser.get(Dialog)).sayById("haveSecretMessage");
			}else if(this.shellApi.checkEvent(_events.FERRIS_WHEEL_STOPPED)){
				Dialog(_guesser.get(Dialog)).sayById("ferrisWheelStopped");
			}else{
				Dialog(_guesser.get(Dialog)).sayById("secretMessage");
			}
		}
		
		private function edgarClicked(...args):void{
			//if (!this.shellApi.checkEvent(_events.SPOKE_EDGAR_FORMULA)){
				//lockControl();
				//Dialog(_edgar.get(Dialog)).sayById("friendsMonsters");	
			//}else{				
				giveEdgarFormula();					
			//}
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			switch(event){
				case "useFormula":
					lockControl();
					CharUtils.moveToTarget(player, _edgar.get(Spatial).x - 140, 1825, false, giveEdgarFormula);						
					break;
				//case "doneChemical":
					//super.shellApi.triggerEvent( _events.SPOKE_EDGAR_FORMULA, true );
					//restoreControl();
					//break;
				//taking care of this universally in UsBlackLightBulbGroup now -Jordan
				//case "used_black_lightbulb":
					//super.shellApi.removeItem(_events.BLACK_LIGHTBULB);
					//super.shellApi.removeItem(_events.FLASHLIGHT);
					//super.shellApi.getItem(_events.FLASHLIGHT_BLACK, null, true);
					//break;
			}
			
		}
		
		private function giveEdgarFormula(...args):void 
		{			
			var actChain:ActionChain = new ActionChain( this );
			actChain.lockInput = true;			
			
			actChain.addAction( new TalkAction( _edgar, "giveCompound" ) );
			
			actChain.execute(this.enterTent);			
			lockControl();
		} 
		
		private function enterTent(...args):void
		{
			this.shellApi.loadScene(RingmastersTent);
			restoreControl();
		}
		
		private function stopCat(...args):void	
		{
			Timeline(_garbage_mc.get(Timeline)).gotoAndStop(1);
		}
		
		private function handleGarbageButtonClicked(entity:Entity):void	
		{
			super.shellApi.triggerEvent("cat");
			Timeline(_garbage_mc.get(Timeline)).gotoAndPlay(2)	
			_garbage_mc.get(Timeline).handleLabel( "end", stopCat );
		}	
		
		private function randomRange(minNum:Number, maxNum:Number):Number 
		{
			var number:Number = (Math.random() * (maxNum - minNum)) + minNum;
			return (number);
		}
		
		private function onStateChange(type:String, entity:Entity):void
		{
			if(type == "stomp")
			{
				super.shellApi.triggerEvent("warrior_angry");
			}
			else if(type == "hit_retreat")
			{
				_wait = true;
				super.shellApi.triggerEvent("warrior_whack");
			}
			else if(type == "stand" && _wait)
			{
				_wait = false;
				var fsmControl:FSMControl = entity.get(FSMControl);
				(fsmControl.getState(type) as MonsterStandState).waitCounter = 4;
			}
		}
		
		private function setupRalphMonster(...args):void
		{

			_ralph.add(new Motion());
			_ralph.add(new Sleep(false, true));
			var _ralphSpatial:Spatial = _ralph.get(Spatial);
				
			var charGroup:CharacterGroup = super.getGroupById("characterGroup") as CharacterGroup;
			charGroup.addFSM( _ralph );
			MotionTarget(_ralph.get(MotionTarget)).targetSpatial = this.player.get(Spatial);
			MotionTarget(_ralph.get(MotionTarget)).useSpatial = false;
			MotionControl(_ralph.get(MotionControl)).lockInput = true;
			MotionControl(_ralph.get(MotionControl)).forceTarget = true;
				
			var fsmControl:FSMControl = new FSMControl(super.shellApi);
			fsmControl.stateChange = new Signal();
			fsmControl.stateChange.add(onStateChange);
			_ralph.add( fsmControl );
				
			var stateCreator:FSMStateCreator = new FSMStateCreator();
			stateCreator.createCharacterStateSet( new <Class>[MonsterStandState, MonsterAttackState, MonsterRetreatState, MonsterHitRetreatState, MonsterStompState], _ralph ); 
				
			MonsterAttackState( fsmControl.getState( "attack" ) ).originalLocation = new Point(_ralphSpatial.x, _ralphSpatial.y);
			MonsterRetreatState( fsmControl.getState( "retreat" ) ).originalLocation = new Point(_ralphSpatial.x, _ralphSpatial.y);
			fsmControl.setState("stand");
			
			var hitCreator:HitCreator = new HitCreator();					
			var hitData:HazardHitData = new HazardHitData();
			hitData.type = "guardHit";
			hitData.knockBackCoolDown = .75;
			hitData.knockBackVelocity = new Point(1800, 500);
			hitData.velocityByHitAngle = false;
			_ralph = hitCreator.makeHit(_ralph, HitType.HAZARD, hitData, this);

		}
		
		private function lockControl(...args):void
		{
			MotionUtils.zeroMotion(super.player, "x");
			CharUtils.lockControls(super.player, true, true);
			SceneUtil.lockInput(this, true);
		}
		
		private function restoreControl(...args):void
		{
			CharUtils.lockControls(super.player, false, false);
			MotionUtils.zeroMotion(super.player);
			SceneUtil.lockInput(this, false);
		}
		
	}
}








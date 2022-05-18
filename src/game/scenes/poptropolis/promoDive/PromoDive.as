package game.scenes.poptropolis.promoDive{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.utils.Timer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.components.hit.MovieClipHit;
	import game.creators.entity.EmitterCreator;
	import game.creators.scene.HitCreator;
	import game.creators.ui.ButtonCreator;
	import game.data.animation.entity.character.Pickaxe;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.scenes.poptropolis.PoptropolisEvents;
	import game.data.profile.TribeData;
	import game.data.scene.hit.HazardHitData;
	import game.data.scene.hit.HitType;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.poptropolis.promoDive.components.Fish;
	import game.scenes.poptropolis.promoDive.components.Jelly;
	import game.scenes.poptropolis.promoDive.components.Shark;
	import game.scenes.poptropolis.promoDive.particles.BubbleStream;
	import game.scenes.poptropolis.promoDive.particles.SandStream;
	import game.scenes.poptropolis.promoDive.systems.PromoDiveSystem;
	import game.scenes.poptropolis.promoPlatform.PromoPlatform;
	import game.systems.entity.EyeSystem;
	import game.systems.hit.MovieClipHitSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TribeUtils;
	import game.util.Utils;
	
	public class PromoDive extends PlatformerGameScene
	{
		private var fish1:Entity;
		private var fish2:Entity;
		private var fish3:Entity;
		private var fish4:Entity;
		private var fish5:Entity;
		private var fish6:Entity;
		private var fish7:Entity;
		private var fish8:Entity;
		private var fish9:Entity;
		private var fish10:Entity;
		private var fishInitializers:Array = new Array();
		private var jellyInitializers:Array = new Array();
		private var sharkInitializers:Array = new Array();
		
		private var _hitCreator:HitCreator;
		public var _interaction:Interaction;
		private var digTarget:Entity;
		private var popEvents:PoptropolisEvents;
		
		private var _bubbleEmitter:BubbleStream;
		private var _bubbleEntity:Entity;
		
		private var sandEmitter:SandStream;
		private var sandEntity:Entity;
		
		private var caveFishLayer:Entity;
		private var caveFishContainer:DisplayObjectContainer;
		
		public var playerStop:Number = 0;
		
		public function PromoDive()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/poptropolis/promoDive/";
			
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
			popEvents = super.events as PoptropolisEvents;
			
			setupPlayerLook();
			setupFish();
			setupJellies();
			setupSharks();
			setupCaveFish();
			
			digTarget = ButtonCreator.createButtonEntity(MovieClip(_hitContainer["sand"]), this);
			_interaction = digTarget.get(Interaction);
			_interaction.downNative.add( Command.create( onDigDown ));			

			_bubbleEmitter = new BubbleStream(); 
			_bubbleEntity = EmitterCreator.create(this, super._hitContainer, _bubbleEmitter, 0, -30, player, "bubbleEntity", player.get(Spatial));
			_bubbleEmitter.init();
			
			//setup diving events
			if(super.shellApi.checkEvent(popEvents.PROMO_DIVE_FINISHED)){
				super.shellApi.removeEvent(popEvents.PROMO_DIVE_FINISHED);
			}
			if(!super.shellApi.checkEvent(popEvents.PROMO_DIVE_STARTED)){
				super.shellApi.completeEvent(popEvents.PROMO_DIVE_STARTED);
			}
			
			super.addSystem(new PromoDiveSystem());
			this.addSystem(new MovieClipHitSystem());
			
			
			/**
			 * Add a MovieClipHit to the player with type "player" and a list of types to test for.
			 * These types become the types of the different entities.
			 * 
			 */
			this.player.add(new MovieClipHit("player", "fish", "jelly", "shark"));
		}
		
		private function onDigDown(event:Event):void 
		{
			CharUtils.lockControls( super.player );
			var item:Entity = CharUtils.getPart(player, "item");
			var state:String = CharUtils.getStateType(player);
			if(state != 'diving' && state != 'hurt'){
				//trace("Digging");
				playerStop = player.get(Spatial).x;
				player.get(Spatial).y = 5000;
				player.get(Spatial).rotation = 0;
				CharUtils.setAnim(player, Pickaxe, false);
				

				player.get(Timeline).handleLabel("loop", makePickSound, false);
		
				//set promo dive finished
				super.shellApi.removeEvent(popEvents.PROMO_DIVE_STARTED);
				super.shellApi.completeEvent(popEvents.PROMO_DIVE_FINISHED);
				if(!super.shellApi.checkEvent(popEvents.DUG_IN_PROMO)){
					super.shellApi.completeEvent(popEvents.DUG_IN_PROMO);
				}
				
				//do brain tracking
				var tribeData:TribeData = TribeUtils.getTribeOfPlayer( super.shellApi );
				if( tribeData ){
					super.shellApi.track("DugGround", tribeData.name, null, "PoptropolisPromo");
				}
				
				//start sand particles
				var xPos:Number;
				if(player.get(Spatial).scaleX > 0){
					xPos = -35;
				}else{
					xPos = 35;
				}
				sandEmitter = new SandStream(); 
				sandEntity = EmitterCreator.create(this, super._hitContainer, sandEmitter, xPos, 40, player, "sandEntity", player.get(Spatial));
				
				
				var sandTimer:Timer = new Timer(500,1);
				sandTimer.addEventListener(TimerEvent.TIMER_COMPLETE, startSand);
				sandTimer.start();
				
				var _startTimer:Timer = new Timer(3000,1);
				_startTimer.addEventListener(TimerEvent.TIMER_COMPLETE, backToPlatform);
				_startTimer.start();
			}
		}
		
		protected function startSand(event:TimerEvent):void
		{
			sandEmitter.init();
			
		}
		
		protected function backToPlatform(event:TimerEvent):void
		{
			super.shellApi.loadScene(PromoPlatform, 1534, 929);
		}
		
		private function setupPlayerLook():void 
		{
			// create a new LookData class
			var lookData:LookData = new LookData();
			lookData.applyAspect( new LookAspectData( SkinUtils.FACIAL, "pg_divesuit" ) );
			lookData.applyAspect( new LookAspectData( SkinUtils.MARKS, "pg_divesuit" ) );
			lookData.applyAspect( new LookAspectData( SkinUtils.OVERSHIRT, "pg_divesuit" ) );
			lookData.applyAspect( new LookAspectData( SkinUtils.ITEM, "pick" ) );
			lookData.applyAspect( new LookAspectData( SkinUtils.PACK, "pfirefighter1" ) );
			
			SkinUtils.applyLook( player, lookData, false );
		}
		
		private function setupSharks():void
		{
			sharkInitializers[0] = [Utils.randInRange(3, 5), -200, 1150, false];
			sharkInitializers[1] = [Utils.randInRange(3, 5), -200, 1150, false];
			
			for(var i:uint=1;i<=2;i++){
				var clip:MovieClip = _hitContainer["shark"+i];
				var s:Entity = new Entity();
				s = TimelineUtils.convertClip( clip, this, s );
				
				var spatial:Spatial = new Spatial();
				spatial.x = clip.x;
				spatial.y = clip.y;
				
				s.add(spatial);
				s.add(new Display(clip));
				s.add(new Shark(sharkInitializers[i-1][0], sharkInitializers[i-1][1], sharkInitializers[i-1][2], sharkInitializers[i-1][3]));
				
				//Shark MovieClipHit
				s.add(new MovieClipHit("shark", "player"));
				
				super.addEntity(s);
				s.get(Display).displayObject["head"].gotoAndStop(1);
				addHit(s);
				
				//s.get(Timeline).handleLabel("bite", makeBiteSound, false);
			}
		}
		
		private function setupJellies():void
		{
			jellyInitializers[0] = [1.5, 3007, 3210];
			jellyInitializers[1] = [.8, 3471, 3650];
			jellyInitializers[2] = [1.5, 3468, 3660];
			
			for(var i:uint=1;i<=3;i++){
				var clip:MovieClip = _hitContainer["j"+i];
				var j:Entity = new Entity();
				
				var spatial:Spatial = new Spatial();
				spatial.x = clip.x;
				spatial.y = clip.y;
				
				j.add(spatial);
				j.add(new Display(clip));
				j.add(new Jelly(jellyInitializers[i-1][0], jellyInitializers[i-1][1], jellyInitializers[i-1][2]));
				
				//Jelly MovieClipHit
				j.add(new MovieClipHit("jelly", "player"));
	
				super.addEntity(j);
				addHit(j);
			}
		}
		
		private function setupFish():void
		{
			fishInitializers[0] = [Utils.randInRange(3, 5), -100, 1050, true, Utils.randInRange(1, 7)];
			fishInitializers[1] = [Utils.randInRange(3, 5), -100, 1050, true, Utils.randInRange(1, 7)];
			fishInitializers[2] = [2, 480, 1100, true, Utils.randInRange(1, 7)];
			fishInitializers[3] = [3, -150, 480, true, Utils.randInRange(1, 7)];
			fishInitializers[4] = [3, 480, 1100, true, Utils.randInRange(1, 7)];
			fishInitializers[5] = [3, -100, 1050, true, Utils.randInRange(1, 7)];
			fishInitializers[6] = [3, -150, 480, true, Utils.randInRange(1, 7)];
			fishInitializers[7] = [3, -150, 400, true, Utils.randInRange(1, 7)];
			fishInitializers[8] = [3, -150, 735, true, Utils.randInRange(1, 7)];
			fishInitializers[9] = [3, -150, 1150, true, Utils.randInRange(1, 7)];
			
			for(var i:uint=1;i<=10;i++){
				var clip:MovieClip = _hitContainer["fish"+i];
				var f:Entity = this["fish"+i];
				f = new Entity();
				
				var spatial:Spatial = new Spatial();
				spatial.x = clip.x;
				spatial.y = clip.y;
				
				f.add(spatial);
				f.add(new Display(clip));
				f.add(new Fish(fishInitializers[i-1][0], fishInitializers[i-1][1], fishInitializers[i-1][2], fishInitializers[i-1][3], clip.y));
				
				//Fish MovieClipHit
				f.add(new MovieClipHit("fish", "player"));
				
				super.addEntity(f);
				f.get(Display).displayObject.gotoAndStop(fishInitializers[i-1][4]);
				addHit(f);
			}
		}
		
		private function setupCaveFish():void
		{
			//get cave fish layer
			caveFishLayer = super.getEntityById("caveFish");
			caveFishContainer = Display(caveFishLayer.get(Display)).displayObject;
			
			for(var i:uint=1;i<=13;i++){
				var clip:MovieClip = MovieClip(caveFishContainer)['f'+i];
				clip.fish.gotoAndPlay(Utils.randInRange(1, 600));
				if(i < 6){
					clip.fish.fish.gotoAndStop(1);
				}else if(i >= 6 && i < 11){
					clip.fish.fish.gotoAndStop(2);
				}else if(i == 11){
					clip.fish.fish.gotoAndStop(1);
				}else{
					clip.fish.fish.gotoAndStop(2);
				}
				clip.mouseEnabled = false;
				clip.mouseChildren = false;
				
				var f:Entity = new Entity();
				
				var spatial:Spatial = new Spatial();
				spatial.x = clip.x;
				spatial.y = clip.y;
				
				f.add(spatial);
				f.add(new Display(clip));
				
				super.addEntity(f);
			}
		}
		
		public function playSharkAttack():void {
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "bear_growl_01.mp3");
			
			//trace("Shark Attack");
		}
		private function makePickSound():void {
			super.shellApi.triggerEvent("startPick");
		}
		public function makeBiteSound():void {
			super.shellApi.triggerEvent("sharkBite");
		}
		
		private function addHit( entity:Entity, coolDown:Number = .75, interval:Number = .75, velocity:Number = 300 ):void
		{
			if( !_hitCreator )
			{
				_hitCreator = new HitCreator();
			}
			
			var hazardHitData:HazardHitData = new HazardHitData();
			hazardHitData.knockBackCoolDown = coolDown;
			hazardHitData.knockBackInterval = interval;
			hazardHitData.velocityByHitAngle = true;
			hazardHitData.knockBackVelocity = new Point(0, velocity);	// when velocityByHitAngle = true knockBackVelocity's length is used to create applied velocity
			_hitCreator.makeHit(entity, HitType.HAZARD, hazardHitData, this);
			
		}
	}
}
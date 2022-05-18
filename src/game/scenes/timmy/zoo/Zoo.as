package game.scenes.timmy.zoo
{
	import com.greensock.easing.Quad;
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.Npc;
	import game.components.entity.character.Skin;
	import game.components.hit.Item;
	import game.components.motion.FollowTarget;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.components.ui.ToolTip;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.scene.characterDialog.DialogData;
	import game.data.sound.SoundModifier;
	import game.scene.template.ItemGroup;
	import game.scenes.timmy.TimmyScene;
	import game.scenes.timmy.zoo.components.Ball;
	import game.scenes.timmy.zoo.systems.BeachballSystem;
	import game.systems.SystemPriorities;
	import game.systems.hit.ItemHitSystem;
	import game.systems.motion.ThresholdSystem;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	
	public class Zoo extends TimmyScene
	{
		private var panTarget:Entity;
		private var pitTarget:Entity;
		private var pitThreshold:Threshold;
		private var bear:Entity;
		private var fanRight:Entity;
		private var fanLeft:Entity;
		
		private var fanClick:Entity;
		private var fanClickInteraction:Interaction;
		public var leftFanSpinning:Boolean;
		public var inPolePosition:Boolean = false;
		
		private var ball:Entity;
		private var pole:Entity;
		private var usingPole:Boolean = false;
		private var fanToolTip:ToolTip;
		
		private var totalFollowing:Boolean =  false;
		private var tigerHead:Entity;
		private var tigerTail:Entity;
		
		private var playerThresholdX:Number = 1410;
		private var fanSounds:AudioRange;
		
//		private var _fanSequence:BitmapSequence;
//		private var _bearSequence:BitmapSequence;
		
		public function Zoo()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/timmy/zoo/";
			
			super.init(container);
		}
		
//		override public function destroy():void
//		{
//			if( _fanSequence )
//			{
//				_fanSequence.destroy();
//				_fanSequence 					=	null;
//			}
////			if( _bearSequence )
////			{
////				_bearSequence.destroy();
////				_bearSequence 					=	null;
////			}	
//			
//			
//			super.destroy();
//		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			setupPanTarget();
			super.loaded();
			
			setupBear();
			setupFans();
			setupBall();
			setupPage();
			setupTiger();
			
			addItemHitSystem();
			
			if(this.getEntityById("bucket")) {
				DisplayUtils.moveToBack( this.getEntityById("bucket").get(Display).displayObject);
			}
			DisplayUtils.moveToBack( this.getEntityById("worker").get(Display).displayObject);
			this.getEntityById("worker").get(Npc).ignoreDepth = true;
			
			if( shellApi.checkEvent( _events.TOTAL_FOLLOWING )) {
				var box:Rectangle = _total.get(MotionBounds).box;
				var rect:Rectangle = new Rectangle(box.x, box.y, 1300, box.height);
				
				_total.remove(MotionBounds);
				_total.add(new MotionBounds(rect));
			}
			
			// MOVE TOTAL AND PLAYER TO TOP LAYER
			DisplayUtils.moveToTop( Display( _total.get( Display )).displayObject );
			DisplayUtils.moveToTop( Display( player.get( Display )).displayObject );
			
			var sceneInteraction:SceneInteraction		=	getEntityById( "worker" ).get( SceneInteraction );
			sceneInteraction.reached.add( talkToWorker );
		}
		
		private function talkToWorker( $player, $worker ):void
		{
			var dialog:Dialog 				=	$worker.get( Dialog );
			
			if( _totalDistraction )
			{
				dialog.sayById( "distracted" );
			}
			else
			{
				dialog.sayById( "normal" );
			}
		}
		
		public function addItemHitSystem():void
		{
			var itemHitSystem:ItemHitSystem 						=	getSystem( ItemHitSystem ) as ItemHitSystem;
			if( !itemHitSystem )	// items require ItemHitSystem, add system if not yet added
			{
				itemHitSystem 										=	new ItemHitSystem();
				addSystem( itemHitSystem, SystemPriorities.resolveCollisions );
			}	
			itemHitSystem.gotItem.removeAll();
			itemHitSystem.gotItem.add( itemHit );
		}
		
		public function itemHit(entity:Entity):void
		{
			var id:Id 				=	entity.get( Id );
			
			if( id.id 			==	_events.HANDBOOK_PAGE )
			{
				getHandbookPage();
			}
			else
			{
				_itemGroup.showAndGetItem( id.id, null, null, null, entity );
			}
		}
		
		private function getHandbookPage( player:Entity = null, handbookPage:Entity = null ):void
		{
			removeEntity( handbookPage );
			shellApi.completeEvent( _events.GOT_DETECTIVE_LOG_PAGE + "3" );
			showDetectivePage( 3 );
		}
		
		override protected function eventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			var itemGroup:ItemGroup = super.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
			if( event == "use_money" ) {
				SceneUtil.lockInput(this, true);
				CharUtils.moveToTarget(player, 750, 833, false, buyNuggets);
			} else if( event == "get_nuggets" ) {
				itemGroup.takeItem( _events.MONEY, "worker", "", null, afterGiveMoney);
			} else if( event == "use_pole" ) {
				if(!usingPole) {
					var hand:Entity = Skin( player.get( Skin )).getSkinPartEntity( "hand1" );
					var handDisplay:Display = hand.get( Display );
					
					pole = EntityUtils.createSpatialEntity(this, _hitContainer["pole"], handDisplay.displayObject);
					pole.get(Spatial).x = 0;
					pole.get(Spatial).y = 0;
					pole.get(Spatial).scaleX = -2.4;
					pole.get(Spatial).scaleY = 2.4;
					pole.get(Spatial).rotation = 0;
					DisplayObject(pole.get(Display).displayObject).parent.setChildIndex(pole.get(Display).displayObject, 0);
					pole.add(new Tween());
					
					usingPole = true;
					fanClick.add( fanToolTip );
					fanClickInteraction.lock = false;
					
					if(player.get(Spatial).x > playerThresholdX) {
						panToPit(false);
					}
				} else {
					this.removeEntity(pole);
					usingPole = false;
					fanClick.remove( ToolTip );
					fanClickInteraction.lock = true;
				}
			} else if( event == "pan_player" ) {
				//panToPlayer();
				SceneUtil.addTimedEvent(this, new TimedEvent(3, 1, panBackCheck, true));
			}
			else
			{
				super.eventTriggered( event, makeCurrent, init, removeEvent );
			}
		}
		
		private function panBackCheck():void {
			if(player.get(Spatial).x > playerThresholdX && !usingPole) {
				panToPlayer();
			}
		}
		
		private function afterGiveMoney():void {
			SceneUtil.lockInput(this, false);
			this.shellApi.removeItem( _events.MONEY );
			var itemGroup:ItemGroup = super.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;	
			itemGroup.showAndGetItem( _events.CHICKEN_NUGGETS, null, null );
			SceneUtil.addTimedEvent(this, new TimedEvent(.25, 1, getChange, true));
		}
		
		private function getChange():void {
			SceneUtil.lockInput(this, false);
			var itemGroup:ItemGroup = super.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
			itemGroup.showAndGetItem( _events.CHANGE, null, null );
		}
		
		private function buyNuggets(entity:Entity):void {
			positionTotal( true, spendMoney );
		}
		
		private function spendMoney():void
		{
			CharUtils.setDirection(player, true);
			Dialog(player.get(Dialog)).sayById("nuggets");
		}
		
		private function setupPanTarget():void {
			panTarget = EntityUtils.createSpatialEntity(this, _hitContainer["panTarget"]);
			pitTarget = EntityUtils.createSpatialEntity(this, _hitContainer["pitTarget"]);
			panTarget.get(Display).alpha = 0;
			pitTarget.get(Display).alpha = 0;
			
			var followTarget:FollowTarget = new FollowTarget( player.get( Spatial ));
			followTarget.offset = new Point( 0, -230 );
			followTarget.properties = new <String>["x", "y"];
			panTarget.add( followTarget );
			
			this.shellApi.camera.jumpToTarget = true;
			super.shellApi.camera.target = panTarget.get(Spatial);
			
			pitThreshold = new Threshold( "x", ">" );
			pitThreshold.threshold = playerThresholdX;
			pitThreshold.entered.add( panToPit );
			pitThreshold.exitted.add( panToPlayer );
			player.add( pitThreshold );
			
			if( !super.systemManager.getSystem( ThresholdSystem )) {
				super.addSystem( new ThresholdSystem());
			}
		}
		
		private function panToPit(say:Boolean=true):void {
			this.shellApi.camera.rate = 0.05;
			//this.shellApi.camera.jumpToTarget = false;
			super.shellApi.camera.target = pitTarget.get(Spatial);
			if(say) {
				if(!shellApi.checkEvent("gotItem_beach_ball")) {
					DialogData(Dialog(player.get(Dialog)).allDialog["fans"]).forceOnScreen = true;
					Dialog(player.get(Dialog)).sayById("fans");
				} else {
					DialogData(Dialog(player.get(Dialog)).allDialog["bear"]).forceOnScreen = true;
					Dialog(player.get(Dialog)).sayById("bear");
				}
			}
			inPolePosition = true;
			
			if( shellApi.checkEvent( _events.TOTAL_FOLLOWING )) {
				CharUtils.stopFollowEntity( _total );
			}
		}
		
		private function panToPlayer():void {
			this.shellApi.camera.rate = 0.1;
			//this.shellApi.camera.jumpToTarget = false;
			super.shellApi.camera.target = panTarget.get(Spatial);
			inPolePosition = false;
			if( shellApi.checkEvent( _events.TOTAL_FOLLOWING )) {
				CharUtils.followEntity(_total, player, new Point( 180, 100 ));
			}
		}
		
		private function setupBear():void {
			var clip:MovieClip 			=	_hitContainer["bear"];
			bear = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH)
			{
				super.convertContainer( clip, PerformanceUtils.defaultBitmapQuality + 1.0 );
			}
			bear = EntityUtils.createMovingTimelineEntity( this, clip, null, true );
			//_bearSequence 				= BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality );
		//	BitmapTimelineCreator.convertToBitmapTimeline(bear, clip, true, _bearSequence, PerformanceUtils.defaultBitmapQuality );
			bear.get(Timeline).gotoAndPlay("idle");
		}
		
		private function setupFans():void {
			var clip:MovieClip 			=	_hitContainer[ "fanRight" ];
			
			if( PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH )
			{
				super.convertContainer( clip, PerformanceUtils.defaultBitmapQuality + 1.0 );
				//		_vendingSequence 			=	BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality + 1.0 );
				//		vendingMachine = BitmapTimelineCreator.createBitmapTimeline( clip, true, true, _vendingSequence, PerformanceUtils.defaultBitmapQuality + 1.0 );
				//		addEntity(vendingMachine);
			}
			//_fanSequence 				=	BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality );
			
			//fanRight = EntityUtils.createSpatialEntity( this, clip, _hitContainer );
			//BitmapTimelineCreator.convertToBitmapTimeline( fanRight, clip, true, _fanSequence, PerformanceUtils.defaultBitmapQuality );
			fanRight = EntityUtils.createMovingTimelineEntity( this, clip );
			Timeline( fanRight.get(Timeline)).gotoAndPlay("spin");
			
			clip 						=	_hitContainer[ "fanLeft" ];
			if( PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH )
			{
				super.convertContainer( clip, PerformanceUtils.defaultBitmapQuality + 1.0 );
			}
			fanLeft = EntityUtils.createMovingTimelineEntity( this, clip );
			
			//fanLeft = EntityUtils.createSpatialEntity( this, clip, _hitContainer );
			//BitmapTimelineCreator.convertToBitmapTimeline( fanLeft, clip, true, _fanSequence, PerformanceUtils.defaultBitmapQuality );
			fanLeft.get(Timeline).gotoAndStop("stopped");
			
			leftFanSpinning = false;
			
			fanClick = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["fanClick"]), this);
			fanClick.remove(Timeline);
			fanClickInteraction = fanClick.get(Interaction);
			fanClickInteraction.downNative.add( Command.create( clickFanBtn ));
			fanClick.get(Display).alpha = 0;
			
			fanToolTip = fanClick.get(ToolTip);
			fanClick.remove(ToolTip);
			fanClickInteraction.lock = true;
			
			//positional fans sound
			var entity:Entity = new Entity();
			var audio:Audio = new Audio();
			audio.play(SoundManager.EFFECTS_PATH + "fan_engine_01_L.mp3", true, [SoundModifier.POSITION, SoundModifier.EFFECTS])
			
			entity.add(audio);
			entity.add(new Spatial(1473, 785));
			entity.add(new AudioRange(1500, 0, 0.6, Quad.easeIn));

			fanSounds = entity.get(AudioRange);
			entity.add(new Id("soundSource"));
			super.addEntity(entity);
		}
		
		private function clickFanBtn(event:Event):void {
			if(usingPole){
				if(leftFanSpinning) {
					fanLeft.get(Timeline).gotoAndStop("stopped");
					fanSounds.maxVolume = 1;
				} else {
					fanLeft.get(Timeline).gotoAndPlay("spin");
					fanSounds.maxVolume = 1.5;
				}
				leftFanSpinning = !leftFanSpinning;
				pressButton();
			}
		}
		
		private function setupBall():void
		{
			var clip:MovieClip = _hitContainer["ball"];
			ball = new Entity();
			var spatial:Spatial = new Spatial();
			spatial.x = clip.x;
			spatial.y = clip.y;
			
			ball.add(spatial);
			ball.add(new Display(clip));
			ball.add(new Ball());
			
			super.addEntity(ball);
			
			if(!shellApi.checkEvent("gotItem_beach_ball")) {
				Ball(ball.get(Ball)).playing = true;
			} else {
				Ball(ball.get(Ball)).playing = false;
				_hitContainer["ball"].visible = false;
				ball.get(Display).visible = false;
			}
			super.addSystem(new BeachballSystem());
		}
		
		public function hitBall():void {
			bear.get(Timeline).gotoAndPlay("bounce");
			this.shellApi.triggerEvent("ball_bounce");
		}
		
		public function endBallGame():void {
			Ball(ball.get(Ball)).playing = false;
			ball.get(Display).visible = false;
			var itemGroup:ItemGroup = super.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
			itemGroup.showAndGetItem( _events.BEACH_BALL, null, null );
			
			if(usingPole) {
				shellApi.triggerEvent("use_pole");
			}
			
			panToPlayer();
		}
		
		public function pressButton():void {
			var tween:Tween = pole.get(Tween);
			var spatial:Spatial = pole.get(Spatial);
			tween.to(spatial, .1, {x:spatial.x - 15, yoyo:true, repeat:1, ease:Sine.easeInOut});
			this.shellApi.triggerEvent("click_fan");
		}
		
		private function setupPage():void {
			var entity:Entity;
			var sceneInteraction:SceneInteraction;
			// HANDBOOK PAGE
			if( shellApi.checkEvent( _events.GOT_DETECTIVE_LOG_PAGE + "3" ))
			{
				removeExtraAssets([ _events.HANDBOOK_PAGE ]);
			}
			else
			{	
				if( shellApi.checkEvent( _events.GOT_DETECTIVE_LOG_PAGE + "2" )) {
					entity						=	makeEntity( _hitContainer[ _events.HANDBOOK_PAGE ], null, null, false, 2 );
					
					InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
					ToolTipCreator.addToEntity( entity );
					
					sceneInteraction			=	new SceneInteraction();
					sceneInteraction.reached.addOnce( getHandbookPage );
					entity.add( sceneInteraction ).add( new Item());
				} else {
					removeExtraAssets([ _events.HANDBOOK_PAGE ]);
				}
			}
		}
		
		private function setupTiger():void {
			var clip:MovieClip	 		=	_hitContainer[ "tigerHead" ];
			if( PerformanceUtils.qualityLevel <= PerformanceUtils.QUALITY_HIGH )
			{
				super.convertContainer( clip, PerformanceUtils.defaultBitmapQuality + 1.0 );
			}
			tigerHead					=	EntityUtils.createMovingTimelineEntity( this, clip, null, true );

			clip 						=	_hitContainer[ "tigerTail" ];
			if( PerformanceUtils.qualityLevel <= PerformanceUtils.QUALITY_HIGH )
			{
				super.convertContainer( clip, PerformanceUtils.defaultBitmapQuality + 1.0 );
			}
			tigerTail					=	EntityUtils.createMovingTimelineEntity( this, clip, null, true );

			tigerHead.get(Timeline).gotoAndPlay(0);
			tigerTail.get(Timeline).gotoAndPlay(0);
		}
		
		private function removeExtraAssets( assets:Array ):void
		{	
			var asset:String;
			
			for each( asset in assets )
			{
				_hitContainer.removeChild( _hitContainer[ asset ]);
			}
		}
	}
}

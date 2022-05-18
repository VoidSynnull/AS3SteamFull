package game.scenes.time.mainStreet
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.group.TransportGroup;
	import engine.util.Command;
	
	import fl.transitions.easing.None;
	
	import game.components.entity.OriginPoint;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterWander;
	import game.components.entity.character.animation.AnimationControl;
	import game.components.entity.character.animation.AnimationSequencer;
	import game.components.hit.Zone;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.components.timeline.TimelineClip;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Stand;
	import game.data.ui.ToolTipType;
	import game.scene.template.PlatformerGameScene;
	import game.scene.template.ads.AdBlimpGroup;
	import game.scenes.custom.AdMiniBillboard;
	import game.scenes.time.TimeEvents;
	import game.scenes.time.mainStreet.popups.TimeNews;
	import game.scenes.time.shared.TimeDeviceButton;
	import game.systems.motion.ThresholdSystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;

	public class MainStreet extends PlatformerGameScene
	{

		public function MainStreet()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/time/mainStreet/";
			
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
			// tool tip on rope
			var rope:Entity = EntityUtils.createSpatialEntity(super, super.hitContainer["climb1"]);
			rope.get(Display).alpha = 0;
			// tool tip text (blank if blimp takeover)
			var toolTipText:String = (super.getGroupById(AdBlimpGroup.GROUP_ID) == null) ? "TRAVEL" : "";			
			ToolTipCreator.addToEntity(rope,ToolTipType.EXIT_UP, toolTipText);
			// rope behavior
			var interaction:Interaction = InteractionCreator.addToEntity(rope, [InteractionCreator.CLICK]);
			interaction.click.add(climbToBlimp);
			
			_events = super.events as TimeEvents;
			super.shellApi.eventTriggered.add(handleEventTriggered);
			super.addSystem(new ThresholdSystem());
			
			Motion(this.player.get(Motion)).maxVelocity.y = 1150;
			
			placeTimeDeviceButton();
			setupConversationSignal();			
			setupNewsBoxClick();
			setupRedLight();
			setupCrab();
			
			_labGirl = getEntityById("labGirl");
			
			if(!super.shellApi.checkHasItem(_events.WARRIOR_MASK))
			{
				if ( SkinUtils.getSkinPart( super.player, SkinUtils.FACIAL ).value == "aztecmask" )
				{
					SkinUtils.setSkinPart(super.player, SkinUtils.FACIAL, "empty");
				}
			}
			if( super.shellApi.checkEvent( _events.TELEPORT ))
			{
				var _transportGroup:TransportGroup = super.addChildGroup( new TransportGroup()) as TransportGroup;
				_transportGroup.transportIn( player, true, .1 );
			}
			var minibillboard:AdMiniBillboard = new AdMiniBillboard(this,super.shellApi, new Point(2160,1590),"minibillboard/minibillboardMedLegs.swf");	
			super.loaded();
		}
		
		private function handleEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			switch(event)
			{
				case _events.ENTERED_LAB:
				{
					// safety
					if(_labGirl.get(AnimationControl)){
						moveNpc(_labGirl,EntityUtils.getPosition(getEntityById("door2")),finishedPath);
					}
					break;
				}					
				default:
				{
					break;
				}
			}
		}

		private function climbToBlimp(ent:Entity):void
		{
			var rope:MovieClip = super.hitContainer["climb1"];
			var top:Number = rope.y - rope.height / 2;
			CharUtils.followPath(player, new <Point>[new Point(rope.x, top)], playerReachedTopBlimp, false, false, new Point(40, 40));
		}		
		
		private function playerReachedTopBlimp(...args):void
		{
			// if blimp takeover not active, then load map
			if (super.getGroupById(AdBlimpGroup.GROUP_ID) == null)
				getEntityById("exitToMap").get(SceneInteraction).activated = true;
		}
		
		private function setupRedLight():void
		{
			var lightClip:MovieClip = super._hitContainer["redLight"] as MovieClip;	
			var lightTimeline:Entity = TimelineUtils.convertClip(lightClip,this);
			if(shellApi.checkEvent(_events.TIME_REPAIRED))
			{
				Timeline(lightTimeline.get(Timeline)).gotoAndStop("off");		
			}
			else
			{
				Timeline(lightTimeline.get(Timeline)).gotoAndPlay("on");		
			}
		}
		
		private function showNewsPaper( character:Entity, interactionEntity:Entity):void
		{
			shellApi.triggerEvent("openPaper");
			var popup:TimeNews = super.addChildGroup(new TimeNews(super.overlayContainer)) as TimeNews;
			popup.id = "timeNews";
		}
		
		private function setupNewsBoxClick():void
		{
			SceneInteraction(super.getEntityById("interaction1").get(SceneInteraction)).reached.add(showNewsPaper);
		}
		
		private function setupConversationSignal():void
		{
			var hit:Entity = super.getEntityById("zone1");
			if(!this.shellApi.checkEvent(this._events.ENTERED_LAB))
			{
				var zone:Zone = hit.get(Zone);
				zone.pointHit = true;
				zone.entered.addOnce(handleConversationSignal);
			}
			else
			{
				this.removeEntity(this._labGirl);
				this._labGirl = null;
				
				this.removeEntity(hit);
			}
		}
		
		private function handleConversationSignal(zoneId:String, characterId:String ):void
		{
			this._labGirl.remove(AnimationSequencer);
			this._labGirl.remove(CharacterWander);
			var interaction:Interaction = this._labGirl.get(Interaction);
			interaction.click.dispatch(this._labGirl);  // only works if click interaction is prepaired already
			SceneUtil.lockInput(this,true,false);
		}

		private function moveNpc(char:Entity, target:Point, finished:Function = null):void
		{
			CharUtils.setAnim(char, Stand, false, 1000, 0,true);
			var path:Vector.<Point> = new Vector.<Point>();
			path.push(EntityUtils.getPosition(char),target);
			//finished(char);
			CharUtils.followPath(char,path,finished);
		}

		private function finishedPath(entity:Entity):void
		{
			removeEntity(entity);
			SceneUtil.lockInput(this,false,false);
		}
		
		private function placeTimeDeviceButton():void
		{
			if(shellApi.checkHasItem(TimeEvents(events).TIME_DEVICE))
			{
				_timeButton = new Entity();
				_timeButton.add(new TimeDeviceButton())
				TimeDeviceButton(_timeButton.get(TimeDeviceButton)).placeButton(_timeButton,this);
			}
		}
		
		////////////////////////////////////// CRAB INTERACTION //////////////////////////////////////
		
		private function setupCrab():void
		{
			_crab = EntityUtils.createMovingEntity(this,_hitContainer["crab"]);
			_crab = TimelineUtils.convertClip(_hitContainer["crab"],this,_crab);
			moveCrab();				
			var interaction:Interaction = InteractionCreator.addToEntity(_crab, [InteractionCreator.CLICK]);
			interaction.click.addOnce(clickCrab);
			ToolTipCreator.addUIRollover(_crab,ToolTipType.CLICK);
			setCrabPieces();
		}
		
		private function resetCrab():void
		{
			Timeline(_crab.get(Timeline)).reset();
			moveCrab();
			Interaction(_crab.get(Interaction)).click.addOnce(clickCrab);
			setCrabPieces();
		}
		
		private function setCrabPieces():void
		{
			for (var i:int = 1; i <= 10; i++) 
			{
				var clip:MovieClip = TimelineClip(_crab.get(TimelineClip)).mc.getChildByName("p"+i) as MovieClip;
				var pc:Entity = EntityUtils.createMovingEntity(this, clip);
				pc.add(new Id("p"+i));
				pc.add(new Sleep(true,true));
				var motion:Motion = Motion(pc.get(Motion));
				pc.add(new OriginPoint(motion.x, motion.y, motion.rotation));
			}
		}
		
		private function moveCrab():void
		{
			Timeline(_crab.get(Timeline)).gotoAndPlay("walk");
			// pick new distance to travel		
			var motion:Motion = _crab.get(Motion);
			var nexGoal:Number = GeomUtils.randomInRange(1190, 725);
			var length:Number = Math.abs(motion.x-nexGoal);			
			while( length < 130 || length > 140){
				nexGoal = GeomUtils.randomInRange(1190, 725);		
				length = Math.abs(motion.x-nexGoal);
			}			
			var tween:Tween = new Tween();
			_crab.add(tween);
			tween.to(motion, 2,{x:nexGoal,ease:None.easeNone, onComplete:Command.create(movedCrab)}, "crabwalk");
		}
		
		private function movedCrab():void
		{
			Timeline(_crab.get(Timeline)).gotoAndStop("walk");
			_crabTimer = SceneUtil.addTimedEvent(this, new TimedEvent(GeomUtils.randomInRange(0.4,2),1,Command.create(moveCrab),true),"crabwait");
		}
		
		private function clickCrab(...params):void
		{
			if(_crabTimer !=null){
				_crabTimer.stop();
			}
			var timeline:Timeline =  _crab.get(Timeline);
			timeline.gotoAndPlay("duck");
			var tween:Tween = _crab.get(Tween);
			tween.pauseAllTweens();
			timeline.handleLabel("retract",clickUnPause);
			_crabClicks++;
			if(_crabClicks >= 10){
				_crabClicks = 0;	
				explodeCrab();
				shellApi.triggerEvent("crabExplode");
			}else{
				var interaction:Interaction = _crab.get(Interaction);
				interaction.click.addOnce(clickCrab);
				shellApi.triggerEvent("clickCrab");
			}			
		}
		
		private function clickUnPause():void
		{
			var tween:Tween = _crab.get(Tween); 
			tween.pauseAllTweens(false);
		}
		
		private function explodeCrab():void
		{
			if(_crabTimer !=null){
				_crabTimer.stop();
			}
			_crab.add(new Tween());
			var timeline:Timeline =  _crab.get(Timeline);
			var interaction:Interaction = _crab.get(Interaction);
			timeline.gotoAndStop("explode");	
			timeline.removeLabelHandler(clickUnPause);
			interaction.click.remove(clickCrab);
			var grav:Number = MotionUtils.GRAVITY;
			var ground:Number = 950;
			for (var i:int = 1; i <= 10; i++) 
			{
				var pc:Entity = getEntityById("p"+i);
				pc.add(new Sleep(false,false));		
				var motion:Motion = Motion(pc.get(Motion));
				pc.add(new OriginPoint(motion.x, motion.y, motion.rotation));
				motion.acceleration.y = grav;
				motion.velocity.x = motion.x/i + Math.random() * 2000 - 1000;
				motion.velocity.y = -((motion.y - ground)/i + Math.random() * 1000 + 200);
				motion.rotationVelocity = Math.random() * 300 - 150;
				motion.friction = new Point(0,0);
				motion.rotationFriction = 0;
				var threshold:Threshold = new Threshold( "y", ">");
				threshold.threshold = 90;
				threshold.entered.add( Command.create(stopCrabPiece, pc) );			
				pc.add( threshold );
			}
		}
		
		// stop motion
		private function stopCrabPiece(pc:Entity):void
		{
			MotionUtils.zeroMotion(pc);
			var motion:Motion = pc.get(Motion);
			motion.rotationAcceleration = 0;
			motion.rotationVelocity = 0;
			++_piecesLanded;
			if(_piecesLanded >= 10){
				_piecesLanded = 0;
				SceneUtil.addTimedEvent(this, new TimedEvent(2.5,1,Command.create(reformCrab),true));	
			}
		}
		
		private function reformCrab():void
		{
			var tween:Tween = _crab.get(Tween);
			for (var i:int=1; i<=10; i++) 
			{
				var pc:Entity = getEntityById("p"+i);
				var motion:Motion = pc.get(Motion);
				var origin:OriginPoint = pc.get(OriginPoint);
				tween.to(motion,0.6,{x:origin.x, y:origin.y, rotation:origin.rotation, onComplete:Command.create(pieceFinished,pc)});
			}		
		}
		
		private function pieceFinished(piece:Entity):void
		{
			EntityUtils.getDisplay(piece).visible = false;
			++_piecesFinished;
			if(_piecesFinished >= 10){
				_piecesFinished = 0;
				Timeline(_crab.get(Timeline)).gotoAndStop("walk");
				SceneUtil.addTimedEvent(this, new TimedEvent(1,1,resetCrab,true));
			}
			removeEntity(piece);
		}
		
		private var _labGirl:Entity;
		private var _timeButton:Entity;
		private var _events:TimeEvents;
		
		// Specific to Crab interaction
		private var _crab:Entity;
		private var _crabClicks:int = 0;
		private var _piecesLanded:int = 0;
		private var _piecesFinished:int = 0;
		private var _crabTimer:TimedEvent;
	}
}
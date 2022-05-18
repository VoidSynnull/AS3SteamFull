package game.scenes.backlot.extSoundStage1
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.hit.Door;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.Angry;
	import game.data.animation.entity.character.Dizzy;
	import game.data.animation.entity.character.Stomp;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.backlot.BacklotEvents;
	import game.scenes.backlot.shared.popups.BacklotBonusComplete;
	import game.components.entity.OriginPoint;
	import game.systems.entity.character.states.CharacterState;
	import game.util.CharUtils;
	import game.util.ColorUtil;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class ExtSoundStage1 extends PlatformerGameScene
	{
		public function ExtSoundStage1()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/backlot/extSoundStage1/";
			
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
			_events = super.events as BacklotEvents;
			super.shellApi.eventTriggered.add( onEventTriggered );
			
			setUpSoundStage1Door();
			setUpFence();
			setUpOverlay();
			setUpCart();
			
			this.setupButterflies();
			this.setupLight();
			this.setupPapers();
			if(shellApi.checkEvent(_events.DAY_2_ESCAPED_LOT) && !shellApi.checkEvent(_events.DAY_2_COMPLETED))
			{
				CharUtils.setAnim(getEntityById("char4"), Angry);
				Timeline(getEntityById("char4").get(Timeline)).handleLabel("ending", sayHow);
				CharUtils.setAnim(getEntityById("char5"), Stomp);
				SceneUtil.lockInput(this);
			}
		}
		
		private function sayHow():void
		{
			Dialog(getEntityById("char4").get(Dialog)).sayById("how");
		}
		
		private function setUpCart():void
		{
			_cart = EntityUtils.createSpatialEntity(this, this._hitContainer["cart"],this._hitContainer);
			var display:Display = _cart.get(Display);
			display.moveToBack();
			if(!super.shellApi.checkEvent(_events.CAN_USE_CART))
			{
				var door:Entity = super.getEntityById("cartExit");
				var interaction:SceneInteraction = door.get(SceneInteraction);
				interaction.reached.removeAll();
				interaction.reached.add(cartReached);
				
				if(shellApi.checkEvent(_events.DISRUPTED_KIRK))
				{
					var entity:Entity =  getEntityById("char2");
					interaction = getEntityById("char2").get(SceneInteraction);
					interaction.reached.addOnce(stopAndListen);
				}
			}
		}
		
		private function stopAndListen(player:Entity, entity:Entity):void
		{
			SceneUtil.lockInput(this);
		}
		
		private function cartReached(player:Entity, door:Entity):void
		{
			if(!super.shellApi.checkEvent(_events.CAN_USE_CART))
			{
				Dialog( super.getEntityById("player").get(Dialog)).sayById("official");
			}
			else
			{
				Door(door.get(Door)).open = true;
			}
		}
		
		private function setUpSoundStage1Door():void
		{
			var door:Entity = super.getEntityById("soundstageExit");
			
			var interaction:SceneInteraction = door.get(SceneInteraction);
			interaction.reached.removeAll();
			interaction.reached.add(soundStageReached);
		}
		
		private function soundStageReached(player:Entity, door:Entity):void
		{
			if(!super.shellApi.checkEvent(_events.TRY_TO_ENTER_SS1))
			{
				super.shellApi.triggerEvent(_events.TRY_TO_ENTER_SS1, true);
				var sophia:Entity = super.getEntityById("char2");
				sophia.get(Display).visible = false;
				SceneUtil.addTimedEvent( super, new TimedEvent( .5, 1, Command.create( enterSophia, sophia, door)));
			}
			else
			{
				Door(door.get(Door)).open = true;
			}
		}
		
		private function enterSophia(sophia:Entity, door:Entity):void
		{
			sophia.get(Spatial).x = door.get(Spatial).x;
			CharUtils.moveToTarget(sophia,3091,1148,true,ruDaCops);
			sophia.get(Display).visible = true;
		}
		
		private function ruDaCops(entity:Entity):void
		{
			Dialog( entity.get(Dialog)).sayById("rudacops");
		}
		
		private function setUpOverlay():void
		{
			_overlay = TimelineUtils.convertClip(this._hitContainer["overlay"],this,_overlay);
			super._hitContainer.addChild(this._hitContainer["overlay"]);
			_overlayTimeline = _overlay.get(Timeline);
			
			if(!super.shellApi.checkEvent(_events.ENTERED_BACKLOT))
			{
				_overlayTimeline.gotoAndStop(0);
				_overlayTimeline.labelReached.add( onLabelTrigger );
				SceneUtil.lockInput(this, true, false);
				CharUtils.lockControls( super.player, true, true );
				CharUtils.setAnim(super.player, Dizzy);
				heyToto("arf1");
			}
			else
			{
				MovieClip( _hitContainer[ "overlay" ]).visible = false;
				super.removeEntity(_overlay);
				super.removeEntity(super.getEntityById("char1"));
			}
		}
		
		private function setUpFence():void
		{
			_fence = TimelineUtils.convertClip( this._hitContainer[ "fence" ], this, _fence);
			_fenceTimeline = _fence.get(Timeline);
			
			_sign = TimelineUtils.convertClip( this._hitContainer[ "signPlate" ], this, _sign);
			_signTimeline = _sign.get(Timeline);
			
			_clasp = TimelineUtils.convertClip( this._hitContainer[ "signClasp" ], this, _clasp);
			_claspTimeline = _clasp.get(Timeline);
			
			if(!super.shellApi.checkEvent(_events.OPENED_BACKLOT_GATE))
			{
				_fenceTimeline.gotoAndStop( 0 );
				_signTimeline.gotoAndStop( 0 );
				_claspTimeline.gotoAndStop( 0 );
				_fenceTimeline.labelReached.add( onLabelTriggerFence );
				_signTimeline.labelReached.add( onLabelTriggerFence );
				_claspTimeline.labelReached.add( onLabelTriggerFence );
				var fence:Entity = super.getEntityById("fenceExit");
				
				var fenceInt:SceneInteraction = fence.get(SceneInteraction);
				fenceInt.reached.removeAll();
				fenceInt.reached.add(doorReached);
			}
			else
			{
				_fenceTimeline.gotoAndStop("opened");
				_signTimeline.gotoAndStop( "opened" );
				_claspTimeline.gotoAndStop( "opened" );
			}
		}
		
		private function doorReached(player:Entity, door:Entity):void
		{
			if(!super.shellApi.checkEvent(_events.OPENED_BACKLOT_GATE))
			{
				_fenceTimeline.paused = false;
				_signTimeline.paused = false;
				_claspTimeline.paused = false;
			}
			else
			{
				Door(door.get(Door)).open = true;
			}
		}
		
		private function onEventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if( event ==_events.ARF_1)
			{
				open();
			}
			if( event ==_events.ARF_2)
			{
				runOff();
			}
			if(event == _events.ENTERED_BACKLOT)
			{
				SceneUtil.lockInput(this, false, false);
				CharUtils.lockControls( super.player, false, false );
			}
			if(event == _events.CAN_USE_CART)
			{
				SceneUtil.lockInput(this, false);
			}
			if(event == _events.BLOW_AWAY_PAGES)
			{
				blowAwayPages();
			}
			if(event == _events.DAY_2_COMPLETED)
			{
				SceneUtil.lockInput(this, false);
				bonusQuestComplete = super.addChildGroup( new BacklotBonusComplete( super.overlayContainer )) as BacklotBonusComplete;
			}
			
			if(event == _events.PAGES_BLEW_AWAY)
			{
				removeEntity(getEntityById("papers"));
			}
		}
		
		private function blowAwayPages():void
		{
			_pagesTimeline = super.getEntityById("papers").get(Timeline);
			_pagesTimeline.handleLabel("ending",pagesBlewAway,true);
			_pagesTimeline.gotoAndPlay(0);
		}
		
		private function pagesBlewAway():void
		{
			shellApi.triggerEvent(_events.PAGES_BLEW_AWAY, true);
		}
		
		private function open():void
		{
			_overlayTimeline.gotoAndPlay(0);
		}
		
		private function runOff():void
		{
			CharUtils.moveToTarget(super.getEntityById("char1"), 2500, 1144,false,ranOff);
		}
		
		private function ranOff(entity:Entity):void
		{
			super.removeEntity(super.getEntityById("char1"));
			super.shellApi.triggerEvent(_events.ENTERED_BACKLOT,true);
		}
		
		private function heyToto(line:String):void
		{
			Dialog( super.getEntityById("char1").get(Dialog)).sayById(line);
		}
		
		private function onLabelTrigger( label:String ):void
		{
			if( label == "ending" )
			{
				_overlayTimeline.stop();
				_overlayTimeline.labelReached.removeAll( );
				heyToto("arf2");
				CharUtils.setState(super.player, CharacterState.STAND);
			}
		}
		
		private function onLabelTriggerFence( label:String ):void
		{
			shellApi.triggerEvent(label);
			if(label == "opened")
			{
				_fenceTimeline.paused = true;
				_claspTimeline.paused = true;
				_signTimeline.paused = true;
				_fenceTimeline.labelReached.removeAll();
				_claspTimeline.labelReached.removeAll();
				_signTimeline.labelReached.removeAll();
				super.shellApi.triggerEvent(_events.OPENED_BACKLOT_GATE, true);
			}
		}
		
		private function setupButterflies():void
		{
			for(var i:int = 1; i <= 2; i++)
			{
				var clip:MovieClip = this._hitContainer["butterfly" + i];
				
				var butterfly:Entity = EntityUtils.createSpatialEntity(this, clip);
				butterfly.add(new SpatialAddition());
				butterfly.add(new WaveMotion());
				butterfly.add(new OriginPoint(clip.x, clip.y));
				butterfly.add(new Tween());
				
				this.moveButterfly(butterfly);
			}
		}
		
		private function moveButterfly(butterfly:Entity):void
		{
			var wave:WaveMotion = butterfly.get(WaveMotion);
			wave.data.length = 0;
			wave.data.push(new WaveMotionData("x", Math.random() * 10, Math.random() / 10));
			wave.data.push(new WaveMotionData("y", Math.random() * 10, Math.random() / 10));
			
			var origin:OriginPoint = butterfly.get(OriginPoint);
			var targetX:Number = (Math.random() - 0.5) * 200 + origin.x;
			var targetY:Number = (Math.random() - 0.5) * 200 + origin.y;
			
			var time:Number = Math.random() * 3 + 8;
			
			var tween:Tween = butterfly.get(Tween);
			tween.to(butterfly.get(Spatial), time, {x:targetX, y:targetY, onComplete:this.moveButterfly, onCompleteParams:[butterfly]});
		}
		
		private function setupLight():void
		{
			var light:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["recordLight"], _hitContainer);
			TimelineUtils.convertClip(_hitContainer["recordLight"], this, light, null, false);
			var lightStatus:Timeline = light.get(Timeline);
			if(!super.shellApi.checkEvent(_events.COMPLETE_STAGE_1))
			{
				lightStatus.gotoAndPlay(0);
			}
			else
			{
				lightStatus.gotoAndStop(0);
				var lightClip:MovieClip = Display(light.get(Display)).displayObject as MovieClip;
				ColorUtil.colorize( lightClip.recordingLight, 0x00FF00 );
			}
		}
		
		private function setupPapers():void
		{
			var papers:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["papers"],_hitContainer);
			TimelineUtils.convertClip(this._hitContainer["papers"], this, papers, null, false);
			papers.add(new Id("papers"));
			if(shellApi.checkEvent(_events.PAGES_BLEW_AWAY))
				removeEntity(getEntityById("papers"));
		}
		
		private var bonusQuestComplete:BacklotBonusComplete;
		
		private var _cart:Entity;
		
		private var _pagesTimeline:Timeline;
		private var _fence:Entity;
		private var _fenceTimeline:Timeline;
		private var _sign:Entity;
		private var _signTimeline:Timeline;
		private var _clasp:Entity;
		private var _claspTimeline:Timeline;
		private var _overlay:Entity;
		private var _overlayTimeline:Timeline;
		private var _darkFade:Display;
		private var _events : BacklotEvents;
	}
}
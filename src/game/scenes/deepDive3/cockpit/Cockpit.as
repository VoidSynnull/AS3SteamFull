package game.scenes.deepDive3.cockpit
{
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.timeline.Timeline;
	import game.components.ui.ToolTip;
	import game.creators.render.LightCreator;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Alerted;
	import game.data.animation.entity.character.BodyShock;
	import game.data.animation.entity.character.Cough;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.HitReact1;
	import game.data.animation.entity.character.HitReact2;
	import game.data.animation.entity.character.KickBack;
	import game.data.animation.entity.character.Pop;
	import game.data.animation.entity.character.Sit;
	import game.data.animation.entity.character.Tremble;
	import game.scene.template.ItemGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.deepDive3.DeepDive3Events;
	import game.scenes.deepDive3.shared.groups.ShipTakeOffGroup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class Cockpit extends PlatformerGameScene
	{
		private var _events:DeepDive3Events;
		private var pulseGradient:Entity;
		private var rings:Entity;
		private var glyphs:Entity;
		private var show:Entity;
		private var message:Entity;
		private var showNum:Number = 1;
		
		private var suit:Entity;
		private var suitClick:Entity;
		private var suitInteraction:Interaction;
		private var consoleClick:Entity;
		private var consoleInteraction:Interaction;
		
		private var _lightOverlay:Entity;
		
		private var panTarget:Entity;
		//private var _lightingGroup:SubsceneLightingGroup;
		
		public function Cockpit()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/deepDive3/cockpit/";
			
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
			_events = DeepDive3Events(events);
			super.shellApi.eventTriggered.add(handleEventTriggered);
			
			setupAnimations();
			setupPanTarget();
			setupLights();
			if(!this.shellApi.checkEvent( "gotItem_atlantis_captain" )){
				setupSuit();
			}else{
				setupConsole();
				var clip:MovieClip = _hitContainer["suit"];
				clip.visible = false;
			}
		}
		
		private function setupLights():void {
			var lightCreator:LightCreator = new LightCreator();
			lightCreator.setupLight(this, super.overlayContainer, 0, false, 0x000033);
			
			_lightOverlay = super.getEntityById("lightOverlay");
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void {
			if( event == "whoOver" ) {
				playSuit();
			}else if( event == "thisWholeOver" ) {
				SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, playShow, true));
			}else if( event == "yearsOver" ) {
				AudioUtils.stop( this, SoundManager.EFFECTS_PATH + "monitor_screen_hum_02_loop.mp3" );
				SceneUtil.addTimedEvent(this, new TimedEvent(3.5, 1, sayLine2, true));
				message.get(Tween).to(message.get(Display), .5, { alpha:1, ease:Sine.easeInOut });
			}else if( event == "getOutOver" ) {
				this.shellApi.completeEvent( this._events.SPOKE_WITH_AI );
				super.shellApi.camera.target = player.get(Spatial);
				player.get(Spatial).rotation = 0;
				CharUtils.moveToTarget(player, 917, 1185, false, unlockScene);
			}
		}
		
		private function unlockScene(entity:Entity):void {
			SceneUtil.lockInput(this, false);
		}
		
		private function playShow():void {
			//trace("play show");
			show.get(Display).alpha = .3;
			show.get(Tween).to(show.get(Display), .5, { alpha:1, yoyo:true, repeat:2, onComplete:show2 });
		}
		
		private function show2():void {
			//trace("show 2");
			rings.get(Tween).to(rings.get(Display), 2, { alpha:.2, ease:Sine.easeInOut });
			glyphs.get(Tween).to(glyphs.get(Display), 2, { alpha:.2, ease:Sine.easeInOut });
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, playFast, true));
		}
		
		private function playFast():void {
			//trace("play fast");
			if(showNum < 13){
				show.get(Timeline).play();
			}
			SceneUtil.addTimedEvent(this, new TimedEvent(.4, 1, advanceFrame, true));
		}
		
		private function advanceFrame():void {
			//trace("advance frame =" +showNum);
			if(showNum < 13){
				show.get(Timeline).gotoAndStop(showNum);
				SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, playFast, true));
				showNum++;
			}else{
				show.get(Tween).to(show.get(Display), 2, { alpha:0, ease:Sine.easeInOut });
				rings.get(Tween).to(rings.get(Display), 2, { alpha:1, ease:Sine.easeInOut });
				glyphs.get(Tween).to(glyphs.get(Display), 2, { alpha:1, ease:Sine.easeInOut });
				sayLine();
			}
		}
		
		private function sayLine():void {
			Dialog(player.get(Dialog)).sayById("years");	
		}
		
		private function sayLine2():void {
			pulseGradient.get(Tween).to(pulseGradient.get(Display), 2, { alpha:0, ease:Sine.easeInOut });
			rings.get(Tween).to(rings.get(Display), 2, { alpha:0, ease:Sine.easeInOut });
			glyphs.get(Tween).to(glyphs.get(Display), 2, { alpha:0, ease:Sine.easeInOut });
			message.get(Tween).to(message.get(Display), 1, { alpha:0, ease:Sine.easeInOut });
			
			shellApi.triggerEvent("shipTakingOff"); // change music
			addChildGroup( new ShipTakeOffGroup( this, _lightOverlay, 0.8, false ));
//			this.addSystem(new ShipTakingOffSystem(this, _lightOverlay, 0.8, false));
			Dialog(player.get(Dialog)).sayById("getOut");	
		}
		
		private function sitDown(entity:Entity=null):void {
			SceneUtil.lockInput(this, true);
			CharUtils.moveToTarget(player, 917, 1185, false, sitDown2);
		}
		
		private function sitDown2(entity:Entity=null):void {
			
			CharUtils.setAnim(player, Sit, false);
			player.get(Spatial).x = 920;
			player.get(Spatial).y = 1120;
			player.get(Spatial).rotation = -20;
			CharUtils.setDirection(player, true);
			super.shellApi.camera.rate = .05;
			super.shellApi.camera.target = panTarget.get(Spatial);
			
			consoleInteraction.downNative.removeAll();
			consoleClick.remove(ToolTip);
			consoleClick.get(Display).visible = false;
			
			powerOnAlien();
		}
		
		private function powerOnAlien():void {
			super.shellApi.triggerEvent("turnAlienOnSound");
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "monitor_screen_hum_02_loop.mp3", .6, true );
			//super.shellApi.triggerEvent("monitorHumSound");
			pulseGradient.get(Tween).to(pulseGradient.get(Display), 2, { alpha:1, ease:Sine.easeInOut });
			rings.get(Tween).to(rings.get(Display), 2, { alpha:1, ease:Sine.easeInOut });
			glyphs.get(Tween).to(glyphs.get(Display), 2, { alpha:1, ease:Sine.easeInOut });
			SceneUtil.addTimedEvent(this, new TimedEvent(3, 1, sayThisWholeLine, true));
		}
		
		private function setupPanTarget():void {
			panTarget = EntityUtils.createSpatialEntity(this, _hitContainer["panTarget"]);
		}
		
		private function clickSuit(event:Event):void {
			SceneUtil.lockInput(this);
			CharUtils.moveToTarget(player, 1010, 1185, false, sayWhoLine);
		}
		
		private function sayThisWholeLine():void {
			Dialog(player.get(Dialog)).sayById("thisWhole");
		}
		
		private function sayWhoLine(entity:Entity):void {
			CharUtils.setDirection(player, false);
			Dialog(player.get(Dialog)).sayById("who");
		}
		
		private function playSuit():void {
			suit.get(Timeline).handleLabel("end", getSuit, true);
			suit.get(Timeline).play();
		}
		
		private function getSuit(entity:Entity=null):void 
		{
			suitInteraction.downNative.removeAll();
			suitClick.remove(ToolTip);
			suitClick.get(Display).visible = false;
			
			//temp
			SceneUtil.lockInput(this, false);
			setupConsole();
			var itemGroup:ItemGroup = super.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
			itemGroup.showAndGetItem( _events.ATLANTIS_CAPTAIN, null, removeSuit );
			//SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, sitDown, true));
		}
		
		private function removeSuit():void {
			suit.get(Display).visible = false;
		}
		
		private function setupConsole():void {
			//click for suit
			consoleClick = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["consoleClick"]), this);
			consoleClick.remove(Timeline);
			consoleInteraction = consoleClick.get(Interaction);
			consoleInteraction.downNative.add( Command.create( clickConsole ));
		}
		
		private function clickConsole(event:Event):void {
			sitDown();
		}
		
		private function setupSuit():void {
			var clip:MovieClip = _hitContainer["suit"];
			
			suit = new Entity();
			suit = TimelineUtils.convertClip( clip, this, suit );
			
			var spatial:Spatial = new Spatial();
			spatial.x = clip.x;
			spatial.y = clip.y;
			
			suit.add(spatial);
			suit.add(new Display(clip));
			suit.add(new Id("suit"));
			
			super.addEntity(suit);
			//show.get(Timeline).gotoAndStop(0);
			
			//click for suit
			suitClick = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["suitClick"]), this);
			suitClick.remove(Timeline);
			suitInteraction = suitClick.get(Interaction);
			suitInteraction.downNative.add( Command.create( clickSuit ));
		}
		
		private function setupAnimations():void {
			pulseGradient = EntityUtils.createSpatialEntity(this, _hitContainer["pulseGradient"], _hitContainer);
			pulseGradient.add(new Tween());
			
			rings = EntityUtils.createSpatialEntity(this, _hitContainer["rings"], _hitContainer);
			TimelineUtils.convertAllClips(_hitContainer["rings"], rings, this, true);
			rings.add(new Tween());
			
			glyphs = EntityUtils.createSpatialEntity(this, _hitContainer["glyphs"], _hitContainer);
			TimelineUtils.convertAllClips(_hitContainer["glyphs"], glyphs, this, true);
			glyphs.add(new Tween());
			
			var clip:MovieClip = _hitContainer["show"];
			
			show = new Entity();
			show = TimelineUtils.convertClip( clip, this, show );
			
			var spatial:Spatial = new Spatial();
			spatial.x = clip.x;
			spatial.y = clip.y;
			
			show.add(spatial);
			show.add(new Display(clip));
			show.add(new Id("show"));
			show.add(new Tween());
			
			super.addEntity(show);
			
			var clip2:MovieClip = _hitContainer["message"];
			
			message = new Entity();
			message = TimelineUtils.convertClip( clip2, this, message );
			
			var spatial2:Spatial = new Spatial();
			spatial2.x = clip2.x;
			spatial2.y = clip2.y;
			
			message.add(spatial);
			message.add(new Display(clip2));
			message.add(new Id("message"));
			message.add(new Tween());
			
			super.addEntity(message);
			
			show.get(Timeline).gotoAndStop(0);
			message.get(Timeline).gotoAndStop(0);
			pulseGradient.get(Display).alpha = 0;
			rings.get(Display).alpha = 0;
			glyphs.get(Display).alpha = 0;
			show.get(Display).alpha = 0;
			message.get(Display).alpha = 0;
		}
	}
}
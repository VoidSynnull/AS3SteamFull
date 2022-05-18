package game.scenes.time.shared
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.components.ui.Button;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.scene.template.CharacterGroup;
	import game.scenes.time.TimeEvents;
	import game.scenes.time.aztec.Aztec;
	import game.scenes.time.china.China;
	import game.scenes.time.edison.Edison;
	import game.scenes.time.everest.Everest;
	import game.scenes.time.france.France;
	import game.scenes.time.graff.Graff;
	import game.scenes.time.greece.Greece;
	import game.scenes.time.lewis.Lewis;
	import game.scenes.time.mainStreet.MainStreet;
	import game.scenes.time.mali.Mali;
	import game.scenes.time.renaissance.Renaissance;
	import game.scenes.time.viking.Viking;
	import game.ui.popup.Popup;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TextUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	
	public class TimeDeviceView extends Popup
	{
		private var events:TimeEvents;
		
		private var readyToTravel:Boolean = false;
		
		private var hintTimer:TimedEvent;
		
		private var spinDuration:Number = 1.0;
		private var spinRotation:Number = 0;
		
		private var times:Dictionary;
		private var locations:Array = [ "Greece", "Viking", "Mali", "Renaissance", "Aztec", "China", "Graff", "Lewis", "Edison", "France", "Everest" ];
		
		// scene class to warp to
		private var targetTime:TimeDeviceData;
		
		private var content:MovieClip;
		
		private var hand:Entity;
		
		private var timeDisplays:Vector.<TextField>;
		
		public function TimeDeviceView(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function destroy():void
		{
			events = null;
			locations = null;
			times = null;
			super.destroy();
		}
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.pauseParent = true;
			super.darkenBackground = true;
			super.groupPrefix = "scenes/time/shared/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.loadFileWithServerFallback("assets/scenes/time/shared/timeDeviceView.swf", gotSwf);
		}
		
		private function gotSwf(clip:MovieClip):void
		{
			if (clip == null)
			{
				trace("swf not loaded");
				return;
			}
			super.screen = clip;
			content = super.screen.content;
			content.x = shellApi.viewportWidth / 2;
			content.y = shellApi.viewportHeight / 2;
			
			super.loadCloseButton();
			super.shellApi.loadFileWithServerFallback("data/scenes/time/shared/npcs.xml", setupHeads);
		}
		
		public function setupHeads(xml:XML):void
		{
			// load the characters into the the groupContainer.
			var characterGroup:CharacterGroup = new CharacterGroup();
			characterGroup.setupGroup(this, content, xml, allCharactersLoaded );
		}
		
		protected function allCharactersLoaded():void
		{
			// position and push heads into background of device
			var faceContainer:DisplayObjectContainer = content["faces"];
			for (var i:int = 1; i < 12; i++)
			{
				var head:Entity = super.getEntityById("head"+i);
				var headclip:Display = head.get(Display);
				var positionClip:MovieClip = faceContainer["face"+i];
				positionClip.y += 20;
				headclip.setContainer(positionClip);
			}
			
			loaded();
		}
		// all assets ready
		override public function loaded():void
		{			
			events = shellApi.islandEvents as TimeEvents;
			times = new Dictionary();
			times["Greece"] = new TimeDeviceData(Greece, 120, "0328BC", events.GOLDEN_VASE);
			times["Viking"] = new TimeDeviceData(Viking, 150, "0831AD", events.AMULET);
			times["Mali"] = new TimeDeviceData(Mali, 180, "1387AD", events.SALT_ROCKS);
			times["Renaissance"] = new TimeDeviceData(Renaissance, 210, "1516AD", events.NOTEBOOK);
			times["Aztec"] = new TimeDeviceData(Aztec, 240, "1519AD", events.SUNSTONE);
			times["China"] = new TimeDeviceData(China, 270, "1593AD", events.STONE_BOWL);
			times["Graff"] = new TimeDeviceData(Graff, 300, "1776AD", events.DECLARATION);
			times["Lewis"] = new TimeDeviceData(Lewis, 330, "1805AD", events.SILVER_MEDAL);
			times["Edison"] = new TimeDeviceData(Edison, 0, "1877AD", events.PHONOGRAPH);
			times["France"] = new TimeDeviceData(France, 30, "1882AD", events.STATUETTE);
			times["Everest"] = new TimeDeviceData(Everest, 60, "1953AD", events.GOGGLES);
			var date:Date = new Date();
			times["MainStreet"] = new TimeDeviceData(MainStreet, 90, date.fullYear.toString()+"AD", events.TIME_REPAIRED);
			date.setFullYear(date.fullYear+50);
			times["MainStreetFuture"] = new TimeDeviceData(MainStreet, 90, date.fullYear.toString()+"AD", events.TIME_REPAIRED);
			
			hand = EntityUtils.createSpatialEntity(this, content["hand"]);
			
			setupKnob();// dealing with the one tf to get it out of the way
			
			setUpGears();
			setUpFlash();
			setUpLid();
			/* bitmapping is breaking the buttons
			if(PlatformUtils.isMobileOS)
			convertContainer(content);//bitmap stuff
			*/
			setUpDial();//tfs are generated not refreshed so bitmapping does not effect this(as long as things are bitmapped first)
			
			setupButtons();
			
			openWatch();
			
			super.loaded();
		}
		
		private function setUpGears():void
		{
			var clip:MovieClip;
			for(var i:int = 0;i < 4; ++i)
			{
				if(i < 3)
				{
					clip = content["reverse"+i];
					EntityUtils.createSpatialEntity(this, clip).add(new Id(clip.name));
				}
				clip = content["forward"+i];
				EntityUtils.createSpatialEntity(this, clip).add(new Id(clip.name));
			}
		}
		
		private function setUpDial():void
		{
			var dial:MovieClip = content["dial"];
			var clip:MovieClip;
			var entity:Entity;
			var blurClip:MovieClip;
			var blur:Entity;
			var tf:TextField;
			var format:TextFormat = new TextFormat(null, 12, 0, true);
			format.align = TextFormatAlign.CENTER;
			timeDisplays = new Vector.<TextField>();
			for(var i:int = 0; i < 6; i++)
			{
				clip = dial["d"+i];
				blurClip = clip["blur"];
				blur = EntityUtils.createSpatialEntity(this, blurClip);
				blur.add(new Id("blur"+i));
				TimelineUtils.convertClip(blurClip, this, blur, null, false);
				EntityUtils.visible(blur, false, true);
				tf = new TextField();
				tf.defaultTextFormat = format;
				tf.alpha = .5;
				tf.x = -7;
				tf.width = 14;
				tf.y = -9;
				tf.height = 17;
				clip.addChild(tf);
				timeDisplays.push(tf);
			}
		}
		
		private function setUpLid():void
		{
			var clip:MovieClip = content["lid"];
			var entity:Entity = TimelineUtils.convertClip(clip, this, null, null, false);
			entity.add(new Id("lid"));
		}
		
		private function setUpFlash():void
		{
			var clip:MovieClip = content["flash"];
			clip.mouseChildren = clip.mouseEnabled = false;
			var entity:Entity = EntityUtils.createSpatialEntity(this, clip);
			TimelineUtils.convertClip(clip, this, entity, null, false);
			entity.add(new Id("flash"));
		}
		
		// check for mobile performace level
		private function get highPerformance():Boolean
		{
			return (PerformanceUtils.QUALITY_HIGH <= PerformanceUtils.qualityLevel);
		}
		
		
		public function openWatch():void
		{
			var entity:Entity = getEntityById("lid");
			var timeline:Timeline = entity.get(Timeline);
			SceneUtil.delay( this, .25, Command.create( onOpenWatchDelay, timeline ) );
		}
		
		private function onOpenWatchDelay( timeline:Timeline ):void
		{
			// open watch lid
			if(highPerformance){
				timeline.gotoAndPlay("opening");
			}else{
				timeline.gotoAndStop("open");
			}
		}
		
		// bring in the buttons from the scene
		private function setupButtons():void
		{
			var subLevel:Number = Number( shellApi.sceneName.charAt( shellApi.sceneName.length - 1 ));
			var sceneName:String;
			var arrayNum:int = -1;
			
			if( subLevel )
			{
				sceneName = shellApi.sceneName.substr( 0, shellApi.sceneName.length-1 );
			}
			else
			{
				sceneName = shellApi.sceneName;
			}
			
			for(var index:uint = 0; index < locations.length; index ++ )
			{
				setupButton( locations[index]);
				if( locations[ index ] == sceneName )
				{
					arrayNum = index;
				}
			}
			
			if(arrayNum>-1)
			{	
				var timeData:TimeDeviceData = times[locations[arrayNum]];
				setHand( timeData.rotation);
				setDial( timeData.date);
				targetTime = timeData;
				setupButton("MainStreet");
			}
			else if( sceneName == "Future" || sceneName == "Future2" || sceneName == "Desolation" || sceneName == "AdStreet")
			{
				setupButton("MainStreet");
				setHand(90);
				setDial(((new Date()).fullYear+50).toString()+"AD");
			}
			else
			{
				setupButton("MainStreet");
				setHand(90);
				setDial((new Date()).fullYear.toString()+"AD");
			}
		}
		
		private function setupKnob():void
		{
			var clip:MovieClip = content.knob;
			var knob:Entity = EntityUtils.createSpatialEntity(this, clip);
			var interaction:Interaction = InteractionCreator.addToEntity(knob, ["click"]);
			interaction.click.add(handleTimeTravel);
			TimelineUtils.convertAllClips(clip, null, this, false, 32, knob);
			ToolTipCreator.addToEntity(knob);
			Timeline(knob.get( Timeline )).gotoAndStop("down");
			
			clip = content.hint;
			TextUtils.refreshText(clip.hint, "CreativeBlock BB");
			var hint:Entity = EntityUtils.createSpatialEntity(this, clip).add(new Id("hint"));
			Display(hint.get(Display)).alpha = 0;
		}
		
		private function setupButton(name:String):void
		{
			var timeData:TimeDeviceData = times[name];
			var clip:MovieClip = content.getChildByName(name) as MovieClip;
			var button:Entity = ButtonCreator.createButtonEntity( clip, this, Command.create( pickScene, timeData));
			checkButton(button, timeData.event);
		}
		
		private function checkButton(button:Entity, event:String):void
		{
			var setCleared:Boolean = false;
			var won:Boolean = false;
			var timeline:Timeline = button.get(Timeline);
			var but:Button = button.get(Button);
			timeline.gotoAndStop("up");
			if(event == events.TIME_REPAIRED && shellApi.checkEvent(events.TIME_REPAIRED)){
				if(shellApi.checkItemEvent(events.MEDAL_TIME)){
					timeline.gotoAndStop("cleared");
					but.isDisabled = true;
				}else{
					timeline.gotoAndPlay("cleared");
					but.isDisabled = true;
				}
			}
			else if(shellApi.checkEvent("returned_"+event)){
				timeline.gotoAndStop("cleared");
				but.isDisabled = true;
			}
		}
		
		private function handleTimeTravel(ent:Entity):void
		{
			//launch time travel
			if(readyToTravel)
			{
				if(highPerformance)
				{
					var flashEntity:Entity = getEntityById("flash");
					Timeline(flashEntity.get(Timeline)).play();
				}
				Timeline(ent.get(Timeline)).gotoAndPlay("lower");			
				// delay warp until anim ends
				SceneUtil.delay(this, 1.5, teleport);
				shellApi.triggerEvent("device_warp");
				hideHint();
			}
		}
		private function teleport():void
		{
			super.shellApi.triggerEvent( events.TELEPORT, true );
			super.shellApi.loadScene( targetTime.scene );
		}
		
		private function pickScene(ent:Entity, timeData:TimeDeviceData):void
		{
			targetTime = timeData;
			setPressed(ent);
			deactivateKnob();
			turnHand(timeData);
			shellApi.triggerEvent("device_select");
		}
		
		private function setPressed(ent:Entity):void
		{
			if(! Button( ent.get(Button) ).isDisabled) 
			{
				Timeline( ent.get(Timeline) ).gotoAndStop("over");
			}
		}
		
		private function setHand(rotation:Number):void
		{
			trace("Checking TimeDevice hand rotation:", rotation);
			if(!isNaN(rotation))
			{
				Spatial(hand.get(Spatial)).rotation = rotation;
			}
		}
		
		private function setDial(date:String, spin:Boolean = false):void
		{
			var entity:Entity;
			var tf:TextField;
			var time:Timeline;
			for(var i:uint=0;i<6;i++)
			{
				entity = getEntityById("blur"+i);
				EntityUtils.visible(entity, spin);
				time = entity.get(Timeline);
				if(spin)
					time.play();
				else
					time.stop();
				
				tf = timeDisplays[i];
				tf.text = date.charAt(i);
				tf.visible = !spin;
			}
		}
		
		private function turnHand(timeData:TimeDeviceData):void
		{
			var direction:int = 1;
			var spatial:Spatial = hand.get(Spatial);
			var dif:Number = timeData.rotation - spatial.rotation;
			
			if(dif > 180)
				dif -= 360;
			if(dif < -180)
				dif += 360;
			
			if(dif < 0)
				direction = -1;
			spinRotation = direction * 360 + timeData.rotation;
			dif = spinRotation - spatial.rotation;
			if(Math.abs(dif) < 360)
				spinRotation += direction * 360;
			// spin to angle
			TweenUtils.entityTo(hand, Spatial, spinDuration, {rotation:spinRotation, ease:Quad.easeIn, onComplete:onHandReady});
			
			var foreGears:Number = 4;
			var revGears:Number = 3;
			var gear:Entity;
			if(highPerformance)
			{
				for(var i:uint=0;i<foreGears;i++)
				{
					gear = getEntityById("forward"+i);
					TweenUtils.entityTo(gear,Spatial,spinDuration,{rotation:spinRotation /2, ease:Quad.easeIn});
					if(i < revGears)
					{
						gear = getEntityById("reverse"+i);
						TweenUtils.entityTo(gear,Spatial,spinDuration,{rotation:-spinRotation / 2, ease:Quad.easeIn});
					}
				}
				setDial(timeData.date, true);
			}
		}
		
		private function onHandReady():void
		{
			Spatial(hand.get(Spatial)).rotation = targetTime.rotation;
			setDial(targetTime.date);
			activateKnob();
			readyToTravel = true;
			shellApi.triggerEvent("device_energize");
		}
		
		private function deactivateKnob():void
		{
			var button:Entity = getEntityById( "knob" );
			var TL:Timeline = Timeline(button.get( Timeline ))
			if(TL.currentFrameData.label != "down"){
				TL.gotoAndPlay("lower");
			}
			hideHint();
		}
		
		private function activateKnob():void
		{
			var button:Entity = getEntityById( "knob" );
			Timeline(button.get( Timeline )).gotoAndPlay("raise");
			hintTimer = SceneUtil.addTimedEvent(this,new TimedEvent(1.5,1,hintAppears,true),"hintTimer");
		}
		
		private function hintAppears():void
		{
			var hint:Entity = getEntityById("hint");
			TweenUtils.entityTo(hint, Display, 1, {alpha:1});
		}
		
		private function hideHint():void
		{
			if(hintTimer)
				hintTimer.stop();
			EntityUtils.getDisplay(getEntityById("hint")).alpha = 0;
		}
	}
}
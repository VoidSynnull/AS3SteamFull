package game.scenes.time.mali{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.ColorTransform;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.group.TransportGroup;
	
	import game.components.entity.character.animation.RigAnimation;
	import game.components.timeline.Timeline;
	import game.data.animation.Animation;
	import game.data.animation.entity.character.Score;
	import game.data.animation.entity.character.Stand;
	import game.data.game.GameEvent;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.time.TimeEvents;
	import game.scenes.time.mali.components.SnakeLunge;
	import game.scenes.time.mali.systems.SnakeLungeSystem;
	import game.scenes.time.shared.TimeDeviceButton;
	import game.systems.SystemPriorities;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	public class Mali extends PlatformerGameScene
	{
		public var _events:TimeEvents;
		
		public function Mali()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/time/mali/";
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
			placeTimeDeviceButton();
			_events = super.events as TimeEvents;			
			super.addSystem( new SnakeLungeSystem(), SystemPriorities.move );			
			var snakeSystem:SnakeLungeSystem = super.getSystem( SnakeLungeSystem ) as SnakeLungeSystem;			
			setUpSnakes();
			setupWindowNpcs();
			super.shellApi.eventTriggered.add(eventTriggers);
			
			if( super.shellApi.checkItemUsedUp(_events.SALT_ROCKS))
			{
				_returnedBool = true;
				var char:Entity = getEntityById("dirtmonger");
				SkinUtils.setSkinPart(char, SkinUtils.ITEM, "bag",true);
				SkinUtils.setSkinPart(char, SkinUtils.MOUTH, "5",true);
			}
			
			if( super.shellApi.checkEvent( _events.TELEPORT ))
			{
				var _transportGroup:TransportGroup = super.addChildGroup( new TransportGroup()) as TransportGroup;
				_transportGroup.transportIn( player, true, .1 );
			}
		}
		
		// process incoming events
		private function eventTriggers(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == GameEvent.GOT_ITEM + _events.SALT_ROCKS)
			{
				if(!shellApi.checkHasItem(_events.SALT_ROCKS) && !_returnedBool)
				{
					shellApi.triggerEvent(_events.ITEM_RETURNED_SOUND);
					if(timeButton){
						timeButton.get(TimeDeviceButton).flashButton();
					}
					_returnedBool = true;
					
					var char:Entity = super.getEntityById("dirtmonger");
					CharUtils.setAnim(char, Score, false, 0, 0, true);
					RigAnimation( CharUtils.getRigAnim( char) ).ended.add( onCelebrateEnd );
				}
			}
		}
		
		private function onCelebrateEnd( anim:Animation = null ):void
		{
			var char:Entity = getEntityById("dirtmonger");
			SkinUtils.setSkinPart(char, SkinUtils.ITEM, "bag",true);
			SkinUtils.setSkinPart(char, SkinUtils.MOUTH, "5",true);
			CharUtils.setAnim(char, Stand, false, 0, 0, true);	
		}
		
		private function setUpSnakes():void
		{
			var total:int = 2;
			var snakeLunge:SnakeLunge;
			var display:Display;
			var snake:Entity;
			var hit:Entity;
			for(var n:int = 0; n < total; n++)
			{
				// get snake graphic and hit
				var clip:MovieClip = _hitContainer["snake" + ( n + 1 )]["hit"];
				snake = TimelineUtils.convertClip(clip, this);
				snake.add(new Id("snake"+ ( n + 1 )));
				Timeline(snake.get(Timeline)).gotoAndPlay("bob");
				hit = super.getEntityById( "snakeHit" + ( n + 1 ));
				// create component
				snakeLunge = new SnakeLunge();
				snakeLunge.strikeSpace = hit.get( Spatial );
				snakeLunge.snakeHit = hit;
				snake.add( snakeLunge );
			}
		}
		
		private function setupWindowNpcs():void
		{
			// pull the windows to the front
			for (var i:int = 0; i < 5; i++) 
			{
				var window:Entity = EntityUtils.createDisplayEntity(this,_hitContainer["window_light"+i]);
				DisplayUtils.moveToTop(EntityUtils.getDisplayObject(window));
			}
			// color hidden npcs all-brown
			var hex:uint = 0x7E5936;
			for (var c:int = 4; c < 8; c++) 
			{
				var char:Entity = getEntityById("char"+c);
				EntityUtils.removeInteraction(char);
				var display:MovieClip = EntityUtils.getDisplayObject( char ) as MovieClip;
				var brown:ColorTransform = new ColorTransform( 1, 1, 1, 0, 0, 0 );
				brown.color = hex;
				display.transform.colorTransform = brown;
				display.mouseEnabled = false;
				display.mouseChildren = false;
			}
			// fix overlays
			DisplayUtils.moveToTop(EntityUtils.getDisplayObject(getEntityById("snake1")));
			DisplayUtils.moveToTop(EntityUtils.getDisplayObject(getEntityById("snake2")));
			DisplayUtils.moveToTop(EntityUtils.getDisplayObject(getEntityById("char3")));
			DisplayUtils.moveToTop(EntityUtils.getDisplayObject(player));
		}
		
		private function placeTimeDeviceButton():void
		{
			if(shellApi.checkHasItem(TimeEvents(events).TIME_DEVICE))
			{
				timeButton = new Entity();
				timeButton.add(new TimeDeviceButton())
				TimeDeviceButton(timeButton.get(TimeDeviceButton)).placeButton(timeButton,this);
			}
		}
		
		private var timeButton:Entity;
		private var _returnedBool:Boolean = false;
	}
}
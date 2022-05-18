package game.scenes.deepDive3.ship
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Spatial;
	import engine.group.TransportGroup;
	import engine.managers.SoundManager;
	
	import game.components.entity.Dialog;
	import game.components.timeline.Timeline;
	import game.data.TimedEvent;
	import game.data.comm.PopResponse;
	import game.data.sound.SoundModifier;
	import game.scene.template.ItemGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.deepDive3.DeepDive3Events;
	import game.scenes.map.map.Map;
	import game.ui.popup.IslandEndingPopup;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class Ship extends PlatformerGameScene
	{
		private var _events:DeepDive3Events;
		private var _octopus:Entity;
		private var _cam:Entity;
		private var _sailor2:Entity;
		
		public function Ship()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/deepDive3/ship/";
			
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
			_events = DeepDive3Events(events);
			super.shellApi.eventTriggered.add(handleEventTriggered);

			super.loaded();
			
			_sailor2 = getEntityById("sailor2");		
			_cam = getEntityById("cam")
			
			var clip:MovieClip;
			clip = super._hitContainer["octopus"];
			_octopus = EntityUtils.createMovingEntity(this,clip);
			TimelineUtils.convertClip( clip, null, _octopus );
			Timeline(_octopus.get(Timeline)).play();
			
			var se:Entity = new Entity();
			var octopusAudio:Audio = new Audio();
			octopusAudio.play(SoundManager.EFFECTS_PATH + "worms_eating_01_L.mp3", true, [SoundModifier.POSITION, SoundModifier.EFFECTS]);
			se.add(octopusAudio);
			se.add(new Spatial(_octopus.get(Spatial).x, _octopus.get(Spatial).y));
			se.add(new AudioRange(600, 0, 1, Quad.easeIn));
			addEntity(se);
			
			if(!super.shellApi.checkEvent(_events.SPOKE_WITH_CAM)){
				SceneUtil.lockInput(this, true);
				super.shellApi.completeEvent(_events.SPOKE_WITH_CAM);
				var _transportGroup:TransportGroup = super.addChildGroup( new TransportGroup()) as TransportGroup;
				_transportGroup.transportIn( player, true, .1 );
				SceneUtil.addTimedEvent(this, new TimedEvent(3.5, 1, camSayLine, true));
			}
		}
		
		private function camSayLine():void {
			SceneUtil.lockInput(this, true);
			Dialog(_cam.get(Dialog)).sayById("whatOnEarth");
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void {
			if( event == "getMedallion" ) {
				//get medallion	
				awardMedallion();
				unlockScene();
			}else if( event == "triggerFadeOut" ) {
				SceneUtil.lockInput( this );
				fadeToBlack();
			}
		}
		
		private function awardMedallion():void {
			if ( !shellApi.checkHasItem( _events.MEDAL_DEEPDIVE3 )) {
				var itemGroup:ItemGroup = super.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
				itemGroup.showAndGetItem( _events.MEDAL_DEEPDIVE3, null, medallionReceived );
			} else {
				medallionReceived();
			}
			
			//shellApi.completedIsland();
		}

		private function medallionReceived():void {
			shellApi.completedIsland('', showPopup);
		}
		
		private function showPopup(response:PopResponse):void 
		{
			SceneUtil.lockInput(this, false);
			var islandEndPopup:IslandEndingPopup = new IslandEndingPopup(this.overlayContainer)
			islandEndPopup.closeButtonInclude = true;
			this.addChildGroup( islandEndPopup );
		}
		
		private function unlockScene():void {
			SceneUtil.lockInput(this, false);
		}
		
		private function fadeToBlack():void {
			shellApi.loadScene( Map, NaN, NaN, null, NaN, 1 );
		}
	}
}
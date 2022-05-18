package game.scenes.hub.theater
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	
	import game.components.entity.Sleep;
	import game.creators.ui.ToolTipCreator;
	import game.data.ui.ToolTipType;
	import game.managers.HouseVideos;
	import game.scene.template.PlatformerGameScene;
	import game.ui.tutorial.TutorialGroup;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;

	public class Theater extends PlatformerGameScene
	{
		// ------ constants ---------- 
		private const LAST_SPIN_DATE:String	= "lastSpinDate";
		private const TEST_WHEEL:String = "test_wheel"
		private const DAYS_PER_MONTH:Array = [31,28,31,30,31,30,31,31,30,31,30,31];
		private const DAYS_PER_MONTH_LEAP_YEAR:Array = [31,29,31,30,31,30,31,31,30,31,30,31];
		
		/**
		 * -- REMOVED DUE TO FEEDBACK TO SET IT TO AUTOPLAY EVERYTIME A USER ENTERS THE THEATER - 0229
		public static const VIDEO_STRING_LSO:String = "hub_theater";
		public static const VIDEO_STRING_LSO_FIELD:String = "videoString";
		public static const VIDEO_STRING_DEFAULT:String = "default";
		 */
		
		public var tutorial:TutorialGroup;
		public const TUTORIAL_ALPHA:Number = .65;
		
		//public static const VIDEO_STRING_USERFIELD:String = "hub_theater_videoString";
		
		// ------- private fields ---- Wheel 0229
		private var daysSinceLastSpin:int = -1;
		private var testingWheel:Boolean = false;
		private var spunAlready:Boolean = false;
		
		
		public function Theater()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{				
			this.groupPrefix = "scenes/hub/theater/";
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
			
			// setup theater door
			var door:MovieClip = MovieClip(this.hitContainer["doorTheater"]);
			//create poster entity
			var poster:Entity = new Entity();
			var display:Display = new Display(door);
			display.isStatic = true;
			poster.add(display);
			poster.add(new Spatial());
			poster.add(new Sleep());
			
			// special tracking
			shellApi.track("EnterMovieTheater");
			
			// add enity to group
			this.addEntity(poster);
			
			if(!PlatformUtils.inBrowser && !PlatformUtils.isMobileOS)
			{
				return;
			}
			
			// add tooltip
			var offset:Point = new Point(0, -door.height/2);
			var text:String = "Play Videos";
			ToolTipCreator.addToEntity(poster, ToolTipType.CLICK, text, offset);
			
			shellApi.eventTriggered.add(onEventTriggered);
			
			// create interaction for clicking on poster
			var interaction:Interaction = InteractionCreator.addToEntity(poster, [InteractionCreator.CLICK], door);
			
			var videos:HouseVideos = new HouseVideos(this, "PlaywireTheaterVideos");
			interaction.click.add(videos.playVideos);
			
			// tracking
			shellApi.track("EnterMovieRoom");
			
			SceneUtil.delay(this, 0.5, videos.playVideos); // autoplay video player on entering the scene			
		}
		
		private function onEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			// no events to monitor yet
		}
	}
}
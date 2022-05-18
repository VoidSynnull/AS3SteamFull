package game.scenes.timmy.skyScraper
{	
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.Npc;
	import game.components.motion.FollowTarget;
	import game.components.motion.Threshold;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.scenes.survival1.shared.components.TriggerHit;
	import game.scenes.survival1.shared.systems.TriggerHitSystem;
	import game.scenes.timmy.TimmyScene;
	import game.scenes.timmy.mainStreet.MainStreet;
	import game.systems.motion.ThresholdSystem;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.RadialDot;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscZone;
	import org.osflash.signals.Signal;
	
	public class SkyScraper extends TimmyScene
	{
		private var timmy:Entity;
		private var timmyThreshold:Threshold;
		private var fallThreshold:Threshold;
		private var timmyFollower:Entity;
		
		private var timmyNum:Number;
		
		private var pieEmitter:Emitter2D;
		private var pieEntity:Entity;
		
		//private var pieOffsetX:Number;
		
		public function SkyScraper()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/timmy/skyScraper/";
			
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
			
			if( shellApi.checkEvent( _events.RETURNED_CAT )) {
				
				timmy = this.getEntityById("timmy");
				DisplayUtils.moveToBack( timmy.get(Display).displayObject);
				timmy.get(Npc).ignoreDepth = true;
				var display:Display = timmy.get( Display );
				display.displayObject[ "shorts" ].alpha = 0;
				display.displayObject[ "shirt_garbage" ].alpha = 0;
				display.displayObject[ "head_garbage" ].alpha = 0;
				
			
				if( shellApi.checkEvent( _events.SAW_TIMMY_ON_TOWER )) {
					if(shellApi.checkEvent( _events.CRASHED_CAR )) {
						timmy = this.getEntityById("timmy");
						this.removeEntity(timmy);
					}
					else if( shellApi.checkItemEvent( _events.CAR_KEY ))
					{
						Dialog( timmy.get( Dialog )).setCurrentById( "steal_the_car" );
					}
				} else  { 
					
		//			if ( !shellApi.checkEvent( _events.SAW_TIMMY_ON_TOWER )) {
						timmyNum = 7;
						setupTimmyFollower();
		//			}
				} 
				
			}
			
			setupFall();
			setupSplash();
		}
		
		private function runTimmy():void
		{
			switch(timmyNum) {
				case 7:
					CharUtils.moveToTarget(player, 520, 744, false, talkToTimmy);
					break;
			}
			
			SceneUtil.lockInput(this, true);
		}
		
		private function talkToTimmy(entity:Entity):void
		{
			Dialog(player.get(Dialog)).sayById("pants");
			CharUtils.setDirection(timmy, true);
		}
		
		
		override protected function eventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void{
			if( event == "talked_with_timmy" ) {
				this.shellApi.completeEvent( _events.SAW_TIMMY_ON_TOWER );
				SceneUtil.lockInput(this, false);
			}
			else
			{
				super.eventTriggered( event, makeCurrent, init, removeEvent );
			}
		}
		
		private function setupTimmyFollower():void {
			timmyFollower = EntityUtils.createSpatialEntity(this, _hitContainer["timmyFollow"]);
			timmyFollower.get(Display).alpha = 0;
			
			var followTarget:FollowTarget = new FollowTarget( player.get( Spatial ));
			//followTarget.offset = new Point( 0, -230 );
			followTarget.properties = new <String>["x", "y"];
			timmyFollower.add( followTarget );
			
			timmyThreshold = new Threshold( "y", "<" );
			timmyThreshold.threshold = 730;
			
			timmyThreshold.entered.addOnce( runTimmy );
			timmyFollower.add( timmyThreshold );
			if( !super.systemManager.getSystem( ThresholdSystem )) {
				super.addSystem( new ThresholdSystem());
			}
			
			if( !super.systemManager.getSystem( ThresholdSystem )) {
				super.addSystem( new ThresholdSystem());
			}
		}
		
		private function setupSplash():void {
			
			addSystem( new TriggerHitSystem());
			
			var triggerPlatform:Entity = getEntityById( "pie" );
			var triggerHit:TriggerHit = new TriggerHit( null, new <String>[ "player" ]);
			triggerHit.triggered = new Signal();
			triggerHit.triggered.add( splash );
			triggerPlatform.add( triggerHit );
			
			pieEmitter = new Emitter2D();
			pieEmitter.counter = new Blast(10);
			pieEmitter.addInitializer( new ImageClass( RadialDot, [1], true, 10 ) );
			pieEmitter.addInitializer( new Velocity( new DiscZone( new Point( 0, 0 ), 150, 100 ) ) );
			pieEmitter.addAction( new ScaleImage( 4, 5 ) );
			pieEmitter.addInitializer( new ColorInit(0xFF0000, 0xFF0000) );
			pieEmitter.addInitializer( new Lifetime(.2,1 ) );
			
			pieEmitter.addAction( new Age() );
			pieEmitter.addAction( new Move() );
			pieEmitter.addAction( new Accelerate(0, 300) );
			pieEmitter.addAction( new Fade( 1, 0.5 ) );
			
			pieEntity = EmitterCreator.create(this, _hitContainer, pieEmitter, 0, 0, null, "pieEmitter", null, false);
			var spatial:Spatial = pieEntity.get(Spatial);
			spatial.x = 1240;
			spatial.y = 1878;
		}
		
		private function splash():void {
			pieEntity.get(Spatial).x = (player.get(Spatial).x);
			SceneUtil.addTimedEvent(this, new TimedEvent(0.1, 1, splash2, true));
		}
		private function splash2():void {
			pieEmitter.start();
		}
		
		private function setupFall():void
		{
			fallThreshold = new Threshold( "y", ">" );
			fallThreshold.threshold = 2400;
			fallThreshold.entered.add( runFall );
			player.add( fallThreshold );
			if( !super.systemManager.getSystem( ThresholdSystem )) {
				super.addSystem( new ThresholdSystem());
			}
		}
		
		private function runFall():void {
			if(player.get(Spatial).x < 800) {
				this.shellApi.loadScene(MainStreet, 1124, 0, "left");
			} else {
				this.shellApi.loadScene(MainStreet, 2438, 0, "right");
			}
		}
	}
}
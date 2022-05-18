package game.scenes.carnival.ridesDay{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.entity.Dialog;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.scenes.carnival.CarnivalEvents;
	import game.data.scene.characterDialog.DialogData;
	import game.data.sound.SoundModifier;
	import game.particles.emitter.SwarmingFlies;
	import game.scene.template.ItemGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.carnival.shared.ferrisWheel.FerrisWheelGroup;
	import game.ui.showItem.ShowItem;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	import org.osflash.signals.Signal;
	
	public class RidesDay extends PlatformerGameScene
	{
		private const FAST_WHEEL_SPEED:Number = 40;
		private const SLOW_WHEEL_SPEED:Number = 0;

		private var _events:CarnivalEvents;
		
		//private var horse1:Entity;
		//private var horse2:Entity;
		private var gears:Entity;
		private var lever:Entity;
		private var doorMidway:Entity;
		private var doorWoods:Entity;
		private var doorTunnelLove:Entity;
		private var doorHauntedLab:Entity;
		private var strengthTarget:Entity;
		private var ferrisWorker:Entity;
		//private var edgar:Entity;
		private var _fliesEntity:Entity;
		private var sparksEmitter:GearSparks;
		private var sparksEmitterEntity:Entity;

		private var ferrisGroup:FerrisWheelGroup;
		
		private var gCampaignName:String = "Carnival";

		public function RidesDay()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carnival/ridesDay/";
			
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
			super.shellApi.eventTriggered.add(handleEventTriggered);
			
			this.ferrisWorker = this.getEntityById("ferrisWheelWorker");
			//this.edgar = this.getEntityById("edgar");
			this.doorMidway = this.getEntityById("doorMidway");
			this.doorWoods = this.getEntityById("doorWoods");
			this.doorTunnelLove = this.getEntityById("doorTunnelLove");
			this.doorHauntedLab = this.getEntityById("doorHauntedLab");
			Dialog(ferrisWorker.get(Dialog)).start.add(checkDialogStart);
			
			setupAnimations();
			setupDoors();
			setupFlies();

			if ( this.shellApi.checkEvent( this._events.REPLACED_LEVER ) ) {

				lever.get( Timeline ).gotoAndStop( 2 );
				this.initFerrisWheel( this.SLOW_WHEEL_SPEED );
				gears.get(Timeline).gotoAndPlay("afterfryoil");
				
				//edgar.get(Spatial).x = 1250;
				//edgar.get(Spatial).y = 1710;
				Dialog(ferrisWorker.get(Dialog)).setCurrentById("fixedFerrisWheel");
				//Dialog(edgar.get(Dialog)).setCurrentById("weCanOpen");

			} else {

				lever.get( Timeline ).gotoAndStop( 0 );
				
				if ( !this.shellApi.checkEvent( this._events.SPOKE_WITH_FERRIS_WORKER ) ) {
					Dialog(ferrisWorker.get(Dialog)).setCurrentById("wheelTooFast");
				}else{
					Dialog(ferrisWorker.get(Dialog)).setCurrentById("findLever");
				}
				this.initFerrisWheel( this.FAST_WHEEL_SPEED );
				setupSparks();
			}

		}

		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void {

			if( event == "closeOpeningDialog" ) {
				SceneUtil.lockInput(this, false);
				this.shellApi.completeEvent( this._events.SPOKE_WITH_FERRIS_WORKER );
				Dialog(ferrisWorker.get(Dialog)).setCurrentById("findLever");

			}else if( event == "lever_used" ) {

				if(Math.abs(player.get(Spatial).x - ferrisWorker.get(Spatial).x) < 300 && Math.abs(player.get(Spatial).y - ferrisWorker.get(Spatial).y) < 300){
					SceneUtil.lockInput(this);				
					CharUtils.moveToTarget(player, ferrisWorker.get(Spatial).x - 100, 1758, false, giveLever);
				}

			}else if( event == "wheelFixed" ) {
				SceneUtil.lockInput(this, false);
				//CharUtils.followPath(edgar, new <Point> [new Point(1250, 1740)], edgarReachedWheel, true);
				
			}else if( event == "openCarnival" ) {
				// NON MEMBER BLOCK
				/*
				var isMem:Boolean = shellApi.profileManager.active.isMember;
				//isMem=true;
				if(!isMem){
					var popup:NonMemberBlockPopup = super.addChildGroup( new NonMemberBlockPopup( super.overlayContainer )) as NonMemberBlockPopup;
					popup.id = "nonMemberBlock";
					return;
				} else {
					//track if member is starting early access
					//REMOVE THIS WHEN EARLY ACCESS PERIOD ENDS
					if(!shellApi.checkEvent(_events.STARTED_EA)){
						shellApi.completeEvent(_events.STARTED_EA);
						if (shellApi.checkEvent(_events.BLOCKED_FROM_EA)) {
						shellApi.track("Demo", "DemoBlock", "Converted", gCampaignName);
						}
					}
					//cutscene popup
					var popup2:DayToDusk = super.addChildGroup( new DayToDusk( super.overlayContainer )) as DayToDusk;
					popup2.id = "dayToDusk";
				}*/
				
				// To get around block for testing -- delete following two lines when uncommenting Non Member Block !!
				//var popup2:DayToDusk = super.addChildGroup( new DayToDusk( super.overlayContainer )) as DayToDusk;
				//popup2.id = "dayToDusk";
			}
		}
		
		//private function afterCutScene():void {
			//super.shellApi.completeEvent(_events.SET_EVENING);
			//super.shellApi.loadScene(RidesEvening, 50, 1758);
		//}
		
		//private function edgarReachedWheel(entity:Entity):void {
			//CharUtils.setDirection(player, false);
			//Dialog(edgar.get(Dialog)).sayById("weCanOpen");
		//}
		
		private function giveLever(entity:Entity):void {

			CharUtils.setDirection(player, true);
			var itemGroup:ItemGroup = super.getGroupById( "itemGroup" ) as ItemGroup;
			itemGroup.takeItem( _events.LEVER, "ferrisWheelWorker" );

			this.shellApi.completeEvent( this._events.REPLACED_LEVER );

			shellApi.removeItem( _events.LEVER );

			var showItem:ShowItem = super.getGroupById( "showItemGroup" ) as ShowItem;
			showItem.transitionComplete.addOnce( runFixedLever );
		}
		
		private function runFixedLever():void {

			lever.get(Timeline).gotoAndPlay(2);
			gears.get(Timeline).gotoAndPlay("afterfryoil");

			var d:Dialog = this.ferrisWorker.get( Dialog ) as Dialog;
			d.speaking = false;
			d.sayById("fixedFerrisWheel");

			d.setCurrentById("fixedFerrisWheel");

			this.ferrisGroup.changeAngularVelocity( this.SLOW_WHEEL_SPEED );
			sparksEmitter.stop();
		}
		
		private function checkDialogStart(dialogData:DialogData):void
		{
			if(dialogData.id == "wheelTooFast" && dialogData.entityID == "ferrisWheelWorker"){
				SceneUtil.lockInput(this);
			}
		}
		
		private function clickClosedRide(door:Entity):void {
			Dialog(player.get(Dialog)).sayById("doorClosed");
		}
		
		private function setupDoors():void {
			var doorTunnelLoveInt:Interaction = doorTunnelLove.get(Interaction);
			doorTunnelLoveInt.click = new Signal();
			doorTunnelLoveInt.click.add(clickClosedRide);
			
			var doorHauntedLabInt:Interaction = doorHauntedLab.get(Interaction);
			doorHauntedLabInt.click = new Signal();
			doorHauntedLabInt.click.add(clickClosedRide);
		}
		
		private function setupFlies():void {
			var fliesEmitter:SwarmingFlies = new SwarmingFlies();
			_fliesEntity = EmitterCreator.create(this, super._hitContainer, fliesEmitter, 0, 0);
			fliesEmitter.init(new Point(590, 1570), 2);
			
			//positional flies sound
			var entity:Entity = new Entity();
			var audio:Audio = new Audio();
			audio.play(SoundManager.EFFECTS_PATH + "insect_flies_02_L.mp3", true, [SoundModifier.POSITION, SoundModifier.EFFECTS])
			//entity.add(new Display(super._hitContainer["soundSource"]));
			entity.add(audio);
			entity.add(new Spatial(590, 1612));
			entity.add(new AudioRange(500, 0, 0.3, Quad.easeIn));
			entity.add(new Id("soundSource"));
			super.addEntity(entity);
		}
		
		private function setupAnimations():void {
			/*var horse1Clip:MovieClip = _hitContainer["horse1"];
			horse1 = new Entity();
			horse1 = TimelineUtils.convertClip( horse1Clip, this, horse1 );
			
			super.addEntity(horse1);
			horse1.get(Timeline).gotoAndStop(1);
			
			var horse2Clip:MovieClip = _hitContainer["horse2"];
			horse2 = new Entity();
			horse2 = TimelineUtils.convertClip( horse2Clip, this, horse2 );
			
			super.addEntity(horse2);
			horse2.get(Timeline).gotoAndStop(1);
			*/
			
			var leverClip:MovieClip = _hitContainer["lever"];
			lever = new Entity();
			lever = TimelineUtils.convertClip( leverClip, this, lever );
			
			super.addEntity(lever);
			lever.get(Timeline).gotoAndStop(1);
			
			var gearsClip:MovieClip = _hitContainer["gears"];
			gears = new Entity();
			gears = TimelineUtils.convertClip( gearsClip, this, gears );
			gears.add(new Spatial(gearsClip.x, gearsClip.y));
			gears.add(new Display(gearsClip));
			
			super.addEntity(gears);
			gears.get(Timeline).gotoAndPlay("superfast");
			
			var strengthTargetClip:MovieClip = _hitContainer["strengthTarget"];
			strengthTarget = new Entity();
			strengthTarget = TimelineUtils.convertClip( strengthTargetClip, this, strengthTarget );
			
			super.addEntity(strengthTarget);
			strengthTarget.get(Timeline).gotoAndStop(1);
		}
		
		private function setupSparks():void {
			sparksEmitter = new GearSparks();
			sparksEmitter.init();
			
			sparksEmitterEntity = EmitterCreator.create( this, super._hitContainer, sparksEmitter, -15, -19, player, "mEmitterEntity", gears.get(Spatial), false );
			
			sparksEmitter.start();
		}

		/**
		 * Angular velocity is currently in degrees per second.
		 */
		private function initFerrisWheel( angularVelocity:Number ):void {

			var grp:FerrisWheelGroup = this.ferrisGroup = new FerrisWheelGroup();
			super.addChildGroup( grp );

			var center:MovieClip = super._hitContainer[ "ferrisAxle" ];

			grp.beginCreate( super._hitContainer as MovieClip, center, angularVelocity );
			grp.addArms( "arm" );
			grp.addSwings( "seat", true, "ferrisPlat" );

			grp.start();

			grp.makeSlipperyPlatforms();

		} //


	}
}
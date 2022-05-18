package game.scenes.carnival.ridesNight{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionTarget;
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.hit.MovieClipHit;
	import game.components.specialAbility.SpecialAbilityControl;
	import game.creators.animation.FSMStateCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.scene.HitCreator;
	import game.scenes.carnival.CarnivalEvents;
	import game.data.scene.hit.HazardHitData;
	import game.data.scene.hit.HitType;
	import game.data.sound.SoundModifier;
	import game.data.specialAbility.SpecialAbilityData;
	import game.data.specialAbility.islands.carnival.CarnivalHammer;
	import game.particles.emitter.SwarmingFlies;
	import game.scene.template.CharacterGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.carnival.ridesDay.GearSparks;
	import game.scenes.carnival.ridesEvening.components.CarouselHorse;
	import game.scenes.carnival.ridesEvening.systems.CarouselSystem;
	import game.scenes.carnival.ridesNight.components.StrengthMonster;
	import game.scenes.carnival.ridesNight.systems.StrengthMonsterSystem;
	import game.scenes.carnival.shared.ferrisWheel.FerrisWheelGroup;
	import game.scenes.carnival.shared.ferrisWheel.components.FerrisAxle;
	import game.scenes.carnival.shared.states.MonsterAttackState;
	import game.scenes.carnival.shared.states.MonsterHitRetreatState;
	import game.scenes.carnival.shared.states.MonsterRetreatState;
	import game.scenes.carnival.shared.states.MonsterStandState;
	import game.scenes.carnival.shared.states.MonsterStompState;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.GetItemAction;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.PanAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	import org.osflash.signals.Signal;
	
	public class RidesNight extends PlatformerGameScene
	{

		private const FAST_FERRIS_SPEED:Number = 44;
		private const SLOW_FERRIS_SPEED:Number = 20;

		private var _events:CarnivalEvents;
		private var _hitCreator:HitCreator;
		private var edgar:Entity
		
		private var strengthTarget:Entity;
		private var gears:Entity;
		private var strengthMonster:Entity;

		private var ferrisGroup:FerrisWheelGroup;
		private var impGroup:ImpGroup;
		
		private var _fliesEntity:Entity;
		private var sparksEmitter:GearSparks;
		private var sparksEmitterEntity:Entity;
		
		private var _macchio:Entity;
		private var _wait:Boolean = false;

		public function RidesNight()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carnival/ridesNight/";
			
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
			
			this.edgar = this.getEntityById("edgar");
			_macchio = super.getEntityById("macchio");

			setupAnimations();
			setupFlies();

			this.player.add(new MovieClipHit("player", "strengthMonster"));

			this.initFerrisWheel();
			
			if ( super.shellApi.checkEvent( this._events.MONSTERS_UNLEASHED ) && !super.shellApi.checkEvent( this._events.SPOKE_EDGAR_FORMULA ) ) {
				if(super.shellApi.sceneManager.previousScene == "game.scenes.carnival.woods::Woods"){
					SceneUtil.lockInput(this, true);
					edgar.get(Spatial).x = 6090;
					edgar.get(Spatial).y = 1752;
					CharUtils.followPath(edgar, new <Point> [new Point(player.get(Spatial).x - 120, player.get(Spatial).y + 30)], edgarReachedPlayer, true);
				}
			}else if ( super.shellApi.checkEvent( this._events.MONSTERS_UNLEASHED ) && super.shellApi.checkEvent( this._events.SPOKE_EDGAR_FORMULA ) && !super.shellApi.checkEvent( this._events.SPOKE_RINGMASTER_FORMULA )) {
				super.removeEntity(edgar);
			}

			if ( super.shellApi.checkEvent( this._events.BEAT_FERRIS_MONSTER ) ) {

				this.removeImpClip();
				this.ferrisGroup.setAngularVelocity( this.SLOW_FERRIS_SPEED );

				if ( super.shellApi.checkHasItem( this._events.FORMULA ) ) {
					Dialog(edgar.get(Dialog)).setCurrentById("getToLab");
				}else{
					Dialog(edgar.get(Dialog)).setCurrentById("ducks");
				}

			} else if ( super.shellApi.checkEvent( this._events.SPOKE_RINGMASTER_FORMULA ) ) {

				// Ferris wheel monster NOT beat but you HAVE talked to ringmaster.
				this.initImp();

				this.ferrisGroup.setAngularVelocity( this.FAST_FERRIS_SPEED );
				setupSparks();

				//Dialog(edgar.get(Dialog)).setCurrentById("slowedDown");

			} else {

				// Haven't beat ferris monster. Haven't talked to ringmaster -> remove imp for now.
				this.removeImpClip();
				this.ferrisGroup.setAngularVelocity( this.SLOW_FERRIS_SPEED );

			} //

			var lever:MovieClip = super._hitContainer["duskLever"];
			if ( lever != null ) {
				lever.gotoAndStop( 1 );
			}

			super.addSystem(new StrengthMonsterSystem());
			
			setupMacchioMonster();
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void {

			/*if( event == "cotton_candy_used" ) {
				if(Math.abs(player.get(Spatial).x - gears.get(Spatial).x) < 300 && Math.abs(player.get(Spatial).y - gears.get(Spatial).y) < 300){
					SceneUtil.lockInput(this);				
					CharUtils.moveToTarget(player, gears.get(Spatial).x, 1758, false, setCottonCandy);
				}
			}*/
			if( event == "doneChemical" ) {
				super.shellApi.completeEvent( _events.SPOKE_EDGAR_FORMULA );
				CharUtils.followPath(edgar, new <Point> [new Point(6090, 1752)], edgarReachedWheel, true);
			}
		}
		
		private function edgarReachedPlayer(entity:Entity):void {
			Dialog(edgar.get(Dialog)).sayById("friendsMonsters");
			CharUtils.setDirection(edgar, true);
		}
		
		private function edgarReachedWheel(entity:Entity):void {
			SceneUtil.lockInput(this, false);
			//edgar.get(Spatial).x = 1595;
			//edgar.get(Spatial).y = 1700;
			super.removeEntity(edgar);
		}
		
		/*private function setCottonCandy(entity:Entity):void {

			this.shellApi.completeEvent( this._events.USED_COTTON_CANDY);

			CharUtils.setDirection(player, true);
			var itemGroup:ItemGroup = super.getGroupById( "itemGroup" ) as ItemGroup;
			itemGroup.takeItem( _events.COTTON_CANDY, "gears" );

			var showItem:ShowItem = super.getGroupById( ShowItem.GROUP_ID ) as ShowItem;
			showItem.transitionComplete.addOnce( this.gummedGears );

			shellApi.removeItem( _events.COTTON_CANDY );
			
			Dialog(edgar.get(Dialog)).setCurrentById("slowedDown");

			//var te:TimedEvent = new TimedEvent(.1, 1, gummedGears, true);
			//SceneUtil.addTimedEvent(this, te);
		}*/

		/*private function gummedGears():void {

			gears.get(Timeline).gotoAndPlay("gummed");
			sparksEmitter.stop();
			SceneUtil.lockInput(this, false);

			var ac:ActionChain = new ActionChain( this );
			ac.lockInput = true;
			ac.addAction( new PanAction( this.impGroup.getImp(), 0.10, 80 ) );
			ac.addAction( new CallFunctionAction( this.ferrisGroup.changeAngularVelocity, [this.SLOW_FERRIS_SPEED] ) );
			ac.addAction( new CallFunctionAction( this.impGroup.slowDown ) );
			ac.addAction( new WaitAction( 2 ) );
			ac.addAction( new PanAction( this.player ) );

			ac.execute();

		}*/

		public function hammerStrike():void {

			if ( this.shellApi.checkEvent( this._events.BEAT_FERRIS_MONSTER ) || this.impGroup == null ||
				!super.shellApi.checkEvent( this._events.SPOKE_RINGMASTER_FORMULA) ) {
				return;
			}

			// Check that player is actually anywhere near the freaking gears.
			// update: now just check youre near the ferris wheel. no gear hitting.
			//var sp:Spatial = this.gears.get( Spatial );
			var ax:FerrisAxle = this.ferrisGroup.getAxle();
			var pSpatial:Spatial = this.player.get( Spatial );

			if ( Math.abs( ax.x - pSpatial.x ) > 1000 ) {
				return
			} //

			this.gears.get( Timeline ).stop();

			///////////////////////////////////////////////////////////////////////////////////stop ferris wheel and drop monster
			Dialog(edgar.get(Dialog)).setCurrentById("ducks");

			this.ferrisGroup.changeAngularVelocity( 0 );

			/**
			 * Need to find the hammer special ability in order to only drop the imp after the hammer is done
				* because the hammer will unlock the scene input and ruin everything.
			 */
			var hammer:CarnivalHammer = ( ( super.player.get( SpecialAbilityControl ) as SpecialAbilityControl ).getSpecialByClass( CarnivalHammer ) as SpecialAbilityData ).specialAbility as CarnivalHammer;
			if ( hammer != null ) {
				hammer.onComplete.addOnce( this.startDropImp );

			}

		}

		private function startDropImp():void {

			this.sparksEmitter.stop();

			var actChain:ActionChain = new ActionChain( this );
			actChain.lockInput = true;
			actChain.autoUnlock = false;
			actChain.addAction( new PanAction( this.impGroup.getImp(), 0.1 ) );
			actChain.addAction( new CallFunctionAction( Command.create(this.impGroup.dropImp, this.onImpHitGround) ) );
			//actChain.addAction( new WaitSignalAction( this.impGroup.onHitGround ) );

			actChain.execute();

		} //

		/**
		 * Need to move the message from the imp's clip to the hitGround and make it collectible.
		 */
		private function onImpHitGround( imp:Entity ):void {
			
			super.shellApi.completeEvent( this._events.BEAT_FERRIS_MONSTER );
			
			var impClip:MovieClip = ( imp.get( Display ) as Display ).displayObject as MovieClip;
			var mc:MovieClip = impClip.getChildByName( "message" ) as MovieClip;
			
			// move message to imp parent so it can be collected.
			impClip.parent.addChild( mc );
			
			/**
			 * All this makes sure the message is in the correct position at the hitContainer level.
			 */
			var mat:Matrix = mc.transform.matrix;
			mat.concat( impClip.transform.matrix );
			mc.transform.matrix = mat;
			
			/**
			 * Change: need to force the player to pick up the ticket right now or we'd have to do
			 * all sorts of complicated checks in case they leave the scene and come back, and put
			 * the ticket right back etc.
			 */
			
			var ac:ActionChain = new ActionChain( this );
			ac.lockInput = true;
			ac.addAction( new PanAction( this.player ) );
			ac.addAction( new CallFunctionAction( disablePlats ) ); // disable platforms on ferris wheel (SAFETY FIX)
			ac.addAction( new MoveAction( super.player, mc ) );
			ac.addAction( new GetItemAction( this._events.SECRET_MESSAGE, true ) );
			ac.addAction( new CallFunctionAction( Command.create(mc.parent.removeChild, mc) ) );
			ac.addAction( new CallFunctionAction( restorePlats ) ); // restore platforms on ferris wheel (SAFETY FIX)
			ac.addAction( new MoveAction( this.edgar, this.player, new Point( 100, 8 ) ) );
			ac.addAction( new TalkAction( this.edgar, "ducks" ) );

			ac.execute();
			
			/**
			 * Make the collectible message entity.
			 */
			/*var e:Entity = new Entity()
			.add( new Display( mc ), Display )
			.add( new Id( "message" ), Id )						// need an Id for interactions to work. Noone mentions that?
			.add( new Spatial( mc.x, mc.y ), Spatial );
			
			this.addEntity( e );
			
			InteractionCreator.addToEntity( e, [ InteractionCreator.CLICK ]);
			// Must add entity to engine before calling ToolTipCreator.addToEntity()
			ToolTipCreator.addToEntity( e );
			
			var sceneInteraction:SceneInteraction = new SceneInteraction();
			sceneInteraction.reached.add( getMessage );
			
			e.add( sceneInteraction );*/
			
		} //

		private function setupFlies():void {
			var fliesEmitter:SwarmingFlies = new SwarmingFlies();
			_fliesEntity = EmitterCreator.create(this, super._hitContainer, fliesEmitter, 0, 0);
			fliesEmitter.init(new Point(570, 1570), 10);
			
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
		
		private function setupSparks():void {
			sparksEmitter = new GearSparks();
			sparksEmitter.init();
			
			sparksEmitterEntity = EmitterCreator.create( this, super._hitContainer, sparksEmitter, -20, -15, player, "mEmitterEntity", gears.get(Spatial), false );
			
			sparksEmitter.start();
		}
		
		private function setupAnimations():void {
			var gearsClip:MovieClip = _hitContainer["gears"];
			gears = new Entity();
			gears = TimelineUtils.convertClip( gearsClip, this, gears );
			gears.add(new Spatial(gearsClip.x, gearsClip.y));
			gears.add(new Display(gearsClip));
			gears.add(new Id("gears"));
			super.addEntity(gears);
			gears.get(Timeline).gotoAndPlay("runNormal");
			
			var strengthTargetClip:MovieClip = _hitContainer["strengthTarget"];
			strengthTarget = new Entity();
			strengthTarget = TimelineUtils.convertClip( strengthTargetClip, this, strengthTarget );
			super.addEntity(strengthTarget);
			strengthTarget.get(Timeline).gotoAndStop(0);			
			
			var clip:MovieClip = _hitContainer["strengthMonster"];
			var s:Entity = new Entity();
			s = TimelineUtils.convertClip( clip, this, s );
			
			var spatial:Spatial = new Spatial();
			spatial.x = clip.x;
			spatial.y = clip.y;
			
			s.add(spatial);
			s.add(new Display(clip));
			
			s.add(new MovieClipHit("strengthMonster", "player"));
			s.add(new StrengthMonster());
			super.addEntity(s);
			addHit(s);
			
			var animations:Array = ["owl1", "owl2", "heartLights", "merryLights", "merryLights2", "balloons1", "balloons2", "balloons3", "horse1", "horse2"];
			
			for (var i:uint=0;i<animations.length;i++){
				var clip2:MovieClip = _hitContainer[animations[i]];
				var entity:Entity = new Entity();
				entity = TimelineUtils.convertClip(clip2, this, entity);
				super.addEntity(entity);
			}
			
			setupCarousel();
		}
		
		private function setupCarousel():void {
			//horses
			for (var i:uint=1;i<4;i++){
				var horseClip:MovieClip = _hitContainer["horse"+i];
				var horse:Entity = new Entity();
				horse = TimelineUtils.convertClip( horseClip, this, horse );
				horse.add(new Spatial(horseClip.x, horseClip.y));
				horse.add(new Display(horseClip));
				horse.add(new Tween());
				horse.add(new CarouselHorse());
				horse.get(CarouselHorse).forward = false;
				if (i==1){
					horse.get(Timeline).gotoAndPlay(1);
				}else if (i==2){
					horse.get(Timeline).gotoAndPlay(33);
				}else if (i==3){
					horse.get(Timeline).gotoAndPlay(66);
				}
				super.addEntity(horse);
				
			}
			
			//Carousel Music
			var entity:Entity = new Entity();
			var audio:Audio = new Audio();
			audio.play(SoundManager.MUSIC_PATH + "carousel_night.mp3", true, [SoundModifier.POSITION, SoundModifier.EFFECTS])
			//entity.add(new Display(super._hitContainer["soundSource"]));
			entity.add(audio);
			entity.add(new Spatial(3720, 1550));
			entity.add(new AudioRange(1000, 0, .8, Quad.easeIn));
			entity.add(new Id("soundSource"));
			super.addEntity(entity);
			
			super.addSystem(new CarouselSystem());
		}
		
		private function addHit( entity:Entity, coolDown:Number = .25, interval:Number = .25, velocity:Number = 1000 ):void
		{
			if( !_hitCreator )
			{
				_hitCreator = new HitCreator();
			}
			
			var hazardHitData:HazardHitData = new HazardHitData();
			hazardHitData.knockBackCoolDown = coolDown;
			hazardHitData.knockBackInterval = interval;
			hazardHitData.velocityByHitAngle = true;
			hazardHitData.knockBackVelocity = new Point(0, velocity);	// when velocityByHitAngle = true knockBackVelocity's length is used to create applied velocity
			_hitCreator.makeHit(entity, HitType.HAZARD, hazardHitData, this);
			
		}

		private function initImp():void {

			var grp:ImpGroup = this.impGroup = new ImpGroup();
			super.addChildGroup( grp );

			grp.init( super.hitContainer as MovieClip );

		} //

		private function removeImpClip():void {

			super.hitContainer.removeChild( super.hitContainer[ "imp" ] );

		} //

		private function getMessage( char:Entity, message:Entity ):void {

			super.shellApi.getItem( _events.SECRET_MESSAGE, null, true );
			this.removeEntity( message );

		} //

		private function initFerrisWheel():void {

			var grp:FerrisWheelGroup = this.ferrisGroup = new FerrisWheelGroup();
			super.addChildGroup( grp );

			var center:MovieClip = super._hitContainer[ "ferrisAxle" ];

			grp.beginCreate( super._hitContainer as MovieClip, center, 10 );
			grp.addArms( "arm" );
			grp.addSwings( "seat", true, "ferrisPlat" );

			grp.start();

		} //
		
		private function disablePlats():void{
			FerrisWheelGroup(super.getGroupById("ferrisGroup")).disablePlats();
		}
		
		private function restorePlats():void{
			FerrisWheelGroup(super.getGroupById("ferrisGroup")).restorePlats();
		}
		
		
		private function onStateChange(type:String, entity:Entity):void
		{
			if(type == "stomp")
			{
				super.shellApi.triggerEvent("warrior_angry");
			}
			else if(type == "hit_retreat")
			{
				_wait = true;
				super.shellApi.triggerEvent("warrior_whack");
			}
			else if(type == "stand" && _wait)
			{
				_wait = false;
				var fsmControl:FSMControl = entity.get(FSMControl);
				(fsmControl.getState(type) as MonsterStandState).waitCounter = 4;
			}
		}
		
		private function setupMacchioMonster(...args):void
		{
			
			_macchio.add(new Motion());
			_macchio.add(new Sleep(false, true));
			var _macchioSpatial:Spatial = _macchio.get(Spatial);
			
			var charGroup:CharacterGroup = super.getGroupById("characterGroup") as CharacterGroup;
			charGroup.addFSM( _macchio );
			MotionTarget(_macchio.get(MotionTarget)).targetSpatial = this.player.get(Spatial);
			MotionTarget(_macchio.get(MotionTarget)).useSpatial = false;
			MotionControl(_macchio.get(MotionControl)).lockInput = true;
			MotionControl(_macchio.get(MotionControl)).forceTarget = true;
			
			var fsmControl:FSMControl = new FSMControl(super.shellApi);
			fsmControl.stateChange = new Signal();
			fsmControl.stateChange.add(onStateChange);
			_macchio.add( fsmControl );
			
			var stateCreator:FSMStateCreator = new FSMStateCreator();
			stateCreator.createCharacterStateSet( new <Class>[MonsterStandState, MonsterAttackState, MonsterRetreatState, MonsterHitRetreatState, MonsterStompState], _macchio ); 
			
			MonsterAttackState( fsmControl.getState( "attack" ) ).originalLocation = new Point(_macchioSpatial.x, _macchioSpatial.y);
			MonsterRetreatState( fsmControl.getState( "retreat" ) ).originalLocation = new Point(_macchioSpatial.x, _macchioSpatial.y);
			fsmControl.setState("stand");
			
			var hitCreator:HitCreator = new HitCreator();					
			var hitData:HazardHitData = new HazardHitData();
			hitData.type = "guardHit";
			hitData.knockBackCoolDown = .75;
			hitData.knockBackVelocity = new Point(1800, 500);
			hitData.velocityByHitAngle = false;
			_macchio = hitCreator.makeHit(_macchio, HitType.HAZARD, hitData, this);
			
		}

	}
}
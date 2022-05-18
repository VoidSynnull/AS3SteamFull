package game.scenes.virusHunter.heart.util {

	import com.greensock.TweenMax;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Children;
	import game.components.timeline.Timeline;
	import game.data.TimedEvent;
	import game.data.scene.characterDialog.DialogData;
	import game.scene.template.ItemGroup;
	import game.scenes.virusHunter.heart.components.ArmSegment;
	import game.scenes.virusHunter.heart.components.QuadVirus;
	import game.scenes.virusHunter.heart.components.RigidArm;
	import game.scenes.virusHunter.heart.components.RigidArmExtend;
	import game.scenes.virusHunter.heart.components.RigidArmMode;
	import game.scenes.virusHunter.shared.ShipScene;
	import game.scenes.virusHunter.shared.data.WeaponType;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.PanAction;
	import game.systems.actionChain.actions.UnlockControlAction;
	import game.systems.actionChain.actions.ZeroMotionAction;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;

	public class QuadVirusUtils {

		private var virusEntity:Entity;
		private var scene:ShipScene;
		private var player:Entity;

		/**
		 * we want to preload the death entity while the death animation begins.
		 * if the animation finishes before deathEntity is ready, playDeath=true
		 * will indicate this. Otherwise deathEntity != null indicates the
		 * death entity is ready.
		 */
		private var deathEntity:Entity;
		private var playAnim:Boolean = false;

		/**
		 * obnoxious - arm extends and retracts get called for each arm, so the callback can't actually happen
		 * until the callback reaches 4.
		 */
		private var armDoneCount:int;
		private var onSceneComplete:Function;			// indicates completion of any little cutscene/virus navigation.

		public function QuadVirusUtils( virusEntity:Entity, scene:ShipScene, player:Entity ) {

			this.virusEntity = virusEntity;
			this.scene = scene;
			this.player = player;

		} //

		public function extendVirusArms( growCallback:Function=null, segmentCallback:Function=null ):void {

			var childArms:Vector.<Entity> = ( virusEntity.get( Children ) as Children ).children;

			var extend:RigidArmExtend = new RigidArmExtend();
			extend.segmentFile = "smallSegment.swf";
			extend.segmentRadius = 28;
			extend.targetSegments = 8;
			extend.extendTime = 0.25;

			armDoneCount = 0;

			if ( segmentCallback ) {
				extend.onSegmentAdded.add( segmentCallback );
			}
			if ( growCallback ) {
				extend.onExtendComplete.add( growCallback );
			}

			var entity:Entity;
			var mode:RigidArmMode;
			for( var i:int = childArms.length-1; i >= 0; i-- ) {
				
				entity = childArms[i];
				entity.add( extend );

				mode = entity.get( RigidArmMode );
				mode.addMode( RigidArmMode.EXTEND );

			} // end for-loop.

		} //

		public function retractVirusArms( growCallback:Function=null, segmentCallback:Function=null ):void {
			
			var childArms:Vector.<Entity> = ( virusEntity.get( Children ) as Children ).children;

			var extend:RigidArmExtend = new RigidArmExtend();
			extend.segmentRadius = 28;
			extend.targetSegments = 2;
			extend.extendTime = 0.25;

			armDoneCount = 0;

			if ( segmentCallback ) {
				extend.onSegmentAdded.add( segmentCallback );
			}
			if ( growCallback ) {
				extend.onExtendComplete.add( growCallback );
			}
			var entity:Entity;
			var mode:RigidArmMode;
			for( var i:int = childArms.length-1; i >= 0; i-- ) {

				entity = childArms[i];
				entity.add( extend );

				mode = entity.get( RigidArmMode );
				mode.removeMode( RigidArmMode.EXTEND );		// just in case.
				mode.addMode( RigidArmMode.RETRACT );

			} // end for-loop.

		} //

		public function doVirusDeathScene( completeFunc:Function=null ):void {

			this.scene.loadFile( "quadVirusDeath.swf", this.virusDeathLoaded );
			this.onSceneComplete = completeFunc;

			this.playAnim = false;			// again....

			SceneUtil.addTimedEvent( this.scene, new TimedEvent( 1.75, 1, playDeathSounds ));
			var deathAction:ActionChain = new ActionChain( this.scene );
			deathAction.lockInput = true;
			deathAction.lockPosition = true;
			deathAction.addAction( new PanAction( virusEntity ) );
			deathAction.addAction( new CallFunctionAction( Command.create(this.retractVirusArms, this.armRetractDone, null) ) );

			// the retract will handle the callback.
			deathAction.execute();

		} //

		private function playDeathSounds():void
		{
			var audio:Audio = virusEntity.get( Audio );
			if( !audio )
			{
				audio = new Audio();
				virusEntity.add( audio );
			}
			audio.play( SoundManager.EFFECTS_PATH + "consume_virus_L.mp3", false );
		}
		
		public function doVirusIntro( onComplete:Function=null ):void {

			this.onSceneComplete = onComplete;

			var introChain:ActionChain = new ActionChain( scene );
			introChain.lockInput = true;
			introChain.lockPosition = true;
			introChain.autoUnlock = false;

			introChain.addAction( new ZeroMotionAction(player) );

			var cf:CallFunctionAction = new CallFunctionAction( Command.create(scene.playMessage, "virus_attack", false ) );
			cf.endDelay = 3;
			introChain.addAction( cf );

			introChain.addAction( new PanAction( virusEntity ) );

			cf = new CallFunctionAction( growVirus );
			cf.endDelay = 0.5;
			introChain.addAction( cf );
			introChain.addAction( new CallFunctionAction( Command.create(extendVirusArms, armExtendDone, null) ) );

			// no callback for the intro action because the callback comes from armExtendDone.
			introChain.execute();

		} //

		private function growVirus():void {

			// yay entities.
			var spatial:Spatial = ( ( virusEntity.get( QuadVirus ) as QuadVirus ).body.get( Spatial ) as Spatial );

			TweenMax.to( spatial, 1, { yoyo:true, scaleX:1.12, scaleY:1.12 } );

		} //

		private function armExtendDone( armEntity:Entity ):void {

			var mode:RigidArmMode = armEntity.get( RigidArmMode );
			mode.removeMode( RigidArmMode.EXTEND );

			var arm:RigidArm = armEntity.get( RigidArm ) as RigidArm;
			arm.saveAngles();

			if ( ++armDoneCount < 4 ) {
				return;
			}

			var resumeChain:ActionChain = new ActionChain( scene );
			resumeChain.autoUnlock = true;
			resumeChain.lockInput = true;

			var pan:PanAction = new PanAction( player );
			pan.startDelay = 2;

			resumeChain.addAction( pan );
			resumeChain.addAction( new UnlockControlAction( player, true ) );

			resumeChain.execute();

			if ( onSceneComplete ) {
				onSceneComplete();
			}
	
		} //

		/**
		 * Initialize something here.
		 */
		//private function armSegmentAdded( armEntity:Entity, segment:ArmSegment ):void {
		//} //

		private function armRetractDone( armEntity:Entity ):void {

			var mode:RigidArmMode = armEntity.get( RigidArmMode );
			mode.removeMode( RigidArmMode.RETRACT );

			if ( ++armDoneCount < 4 ) {
				return;
			}

			if ( deathEntity != null ) {
				playDeathAnim();
			} else {
				playAnim = true;
			}

		} //
		
		//private function armSegmentRemoved( armEntity:Entity, segment:ArmSegment ):void {
		//} //

		public function virusDeathLoaded( deathClip:MovieClip ):void {

			if ( deathClip == null ) {
				trace( "End animation not loaded." );
				return;
			}

			this.deathEntity = TimelineUtils.convertClip( deathClip, this.scene );
			this.deathEntity.add( new Display( deathClip ), Display );

			if ( this.playAnim ) {
				this.playDeathAnim();
			}

		} //

		private function playDeathAnim():void {

			var deathClip:DisplayObjectContainer = ( deathEntity.get( Display ) as Display ).displayObject;

			// add the death clip to the virus' parent.
			var virusDisplay:Display = ( virusEntity.get( Display ) as Display );
			virusDisplay.displayObject.parent.addChild( deathClip );
			virusDisplay.visible = false;

			var virusSpatial:Spatial = virusEntity.get( Spatial );

			var deathSpatial:Spatial = new Spatial( virusSpatial.x, virusSpatial.y );
			deathSpatial.rotation = virusSpatial.rotation - 90;			// natural virus rotation is actually on its side.
			deathEntity.add( deathSpatial, Spatial );

			var tl:Timeline = deathEntity.get( Timeline ) as Timeline;
			tl.labelReached.add( this.waitDeathEnd );
			tl.gotoAndPlay( 1 );

		} //

		public function waitDeathEnd( label:String ):void {

			if ( label == "end" ) {

				var tl:Timeline = this.deathEntity.get( Timeline ) as Timeline;
				tl.labelReached.remove( this.waitDeathEnd );

				var sp:Spatial = this.deathEntity.get( Spatial );
				this.scene.addSceneItem( WeaponType.GOO, sp.x, sp.y );

				this.scene.removeEntity( this.deathEntity, true );
				this.scene.removeEntity( this.virusEntity, true );

				this.scene.playMessage( "sample_taken", false );

				SceneUtil.setCameraTarget( this.scene, player );

				//var itemGroup:ItemGroup = scene.getGroupById( "itemGroup" ) as ItemGroup;
				//itemGroup.pause();

				if ( onSceneComplete ) {
					onSceneComplete();
				}

			} //

		} //

		private function defeatedDone( dData:DialogData ):void {

			var itemGroup:ItemGroup = scene.getGroupById( "itemGroup" ) as ItemGroup;
			itemGroup.unpause();

			// don't actually need to do this probably.
			if ( onSceneComplete ) {
				onSceneComplete();
			}

		} //

		// explode the virus arm segments.
		public function explode():void {

			var armEntity:Entity;

			var arm:RigidArm;
			var segment:ArmSegment;

			var vSpatial:Spatial = virusEntity.get( Spatial );
			var motion:Motion;
			var vel:Number;

			var children:Vector.<Entity> = ( virusEntity.get( Children ) as Children ).children;
			for( var i:int = children.length-1; i >= 0; i-- ) {

				armEntity = children[i];
				arm = armEntity.get( RigidArm ) as RigidArm;

				for( var j:int = arm.segments.length-1; j >= 0; j-- ) {

					segment = arm.segments[j];
					motion = segment.entity.get( Motion ) as Motion;

				} // end for-loop.

				this.scene.removeEntity( armEntity );

			} // end for-loop.

		} //

	} // End QuadVirusUtils

} // End package
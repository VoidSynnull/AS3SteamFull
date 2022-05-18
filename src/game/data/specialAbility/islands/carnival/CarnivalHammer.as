// Used by:
// Card "hammer" using item mc_hammer

package game.data.specialAbility.islands.carnival
{
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.group.Scene;
	import engine.systems.CameraSystem;
	
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.SledgeHammer;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.particles.emitter.specialAbility.HammerImpact;
	import game.particles.emitter.specialAbility.ScreenDust;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.Utils;
	
	import org.osflash.signals.Signal;
	
	/**
	 * Swing and smash hammer with explosion
	 */
	public class CarnivalHammer extends SpecialAbility
	{
		private var targetEntity:Entity;	
		private var targetStartX:Number;
		private var targetStartY:Number;
		private var shake:Boolean = false;
		private var bottomLimit:Number;
		private var topLimit:Number;
		private var leftLimit:Number;
		private var rightLimit:Number;

		public var onComplete:Signal;		// basic signal for when the hammer finishes its strike. No parameters.

		// On activate, load the file passed in as a param
		override public function activate( node:SpecialAbilityNode ):void
		{
			if ( this.onComplete == null ) {
				this.onComplete = new Signal();
			}

			var scene:Scene = super.group as Scene;
			
			if("stopHammerStrike" in scene){
				var stopHammer:Boolean = scene["stopHammerStrike"]();
				if(stopHammer == true){
					return;
				}
			}
			
			if(!super.data.isActive) {
				var state:String = CharUtils.getStateType(node.entity);
				if(state == 'stand' || state == 'walk' || state == 'run' || state == 'skid' || state == 'duck' || state == 'idle'){
					targetEntity = new Entity();
					targetEntity.add(new Spatial());
					targetEntity.get(Spatial).x = node.entity.get(Spatial).x;
					targetEntity.get(Spatial).y = node.entity.get(Spatial).y;
					targetStartX = targetEntity.get(Spatial).x;
					targetStartY = targetEntity.get(Spatial).y;
					var camera:CameraSystem = scene.shellApi.camera as CameraSystem;
					if ( camera )
					{
						bottomLimit = camera.areaHeight - (camera.viewportHeight/2) - 10;
						topLimit = (camera.viewportHeight/2) + 10;
						leftLimit = (camera.viewportWidth/2) + 10;
						rightLimit = camera.areaWidth - (camera.viewportWidth/2) - 10;
						if(targetStartY > bottomLimit){
							targetStartY = bottomLimit;
						}
						if(targetStartY < topLimit){
							targetStartY = topLimit;
						}
						if(targetStartX < leftLimit){
							targetStartX = leftLimit;
						}
						if(targetStartX > rightLimit){
							targetStartX = rightLimit;
						}
					}
					scene.addEntity(targetEntity);
					SceneUtil.setCameraTarget(scene, targetEntity);
					SceneUtil.lockInput(scene);
					CharUtils.setAnim(node.entity, SledgeHammer);
					CharUtils.getTimeline(node.entity).handleLabel("trigger", hammerSwing);
					CharUtils.getTimeline(node.entity).handleLabel("trigger", smashExplosion);
					MotionUtils.zeroMotion(node.entity);
					super.setActive(true);
					// Timer to kill that entity later
					SceneUtil.addTimedEvent(scene, new TimedEvent(2, 1, endShake));
				}
			}
		}
		
		private function smashExplosion():void
		{
			// impact sparks
			var sparks:HammerImpact = new HammerImpact();
			sparks.init();
			var hammerHead:MovieClip = CharUtils.getPart(super.entity, CharUtils.ITEM).get(Display).displayObject["active_obj"]["head"];
			EmitterCreator.create(super.group, hammerHead, sparks, 0, 0);
			// screen wide dust poofs
			if(super.shellApi.sceneName != "MirrorMaze"){
				var dust:ScreenDust = new ScreenDust();
				dust.init();
				EmitterCreator.createSceneWide(Scene(super.group), dust, true);
			}
			// sound
			AudioUtils.getAudio(super.group,"sceneSound").play("effects/smash_01.mp3");
		}
		
		private function endShake():void {
			SceneUtil.lockInput(super.group, false);
			SceneUtil.setCameraTarget(Scene(super.group), super.entity);
			super.group.removeEntity(targetEntity);
			super.setActive(false);
			shake = false;

			this.onComplete.dispatch();
		}
		
		private function hammerSwing():void
		{
			var scene:Scene = super.group as Scene;
			if("hammerStrike" in scene){
				scene["hammerStrike"]();
			}else{
				trace("CarnivalHammer :: No function 'hammerStrike' in scene.");
			}
			shake = true;
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{

			if ( this.onComplete != null ) {
				this.onComplete.removeAll();
				this.onComplete = null;
			}
		}
		
		override public function update(node:SpecialAbilityNode, time:Number):void {
			if(shake){
				targetEntity.get(Spatial).x = targetStartX + Utils.randInRange(-20, 20);
				targetEntity.get(Spatial).y = targetStartY + Utils.randInRange(-20, 20);
				
			}
		}
	}
}
package game.scenes.ftue.outro.groups
{
	import com.greensock.easing.Cubic;
	
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.hit.Hazard;
	import game.components.motion.Threshold;
	import game.data.animation.entity.character.Laugh;
	import game.data.animation.entity.character.Place;
	import game.data.animation.entity.character.Throw;
	import game.data.scene.hit.HazardHitData;
	import game.scenes.ftue.outro.Outro;
	import game.scenes.ftue.outro.systems.FokkerBombSystem;
	import game.systems.SystemPriorities;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.WaitAction;
	import game.systems.hit.HazardHitSystem;
	import game.systems.motion.ThresholdSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	
	public class FokkerBombGroup extends Group
	{
		public static const GROUP_ID:String								= "fokkerBombGroup";
		
		public function FokkerBombGroup()
		{
			super();
			
			this.id = GROUP_ID;
		}
		
		override public function added():void
		{
			if(!this.parent.hasSystem(HazardHitSystem)){
				this.parent.addSystem(new HazardHitSystem(), SystemPriorities.update);
			}
			
			var outro:Outro = this.parent as Outro;
			
			this.addSystem(new FokkerBombSystem(), SystemPriorities.update);
			
			this.addSystem(new ThresholdSystem());
			
			bombPlayer();
		}
		
		public function bombPlayer():void
		{
			var outro:Outro = this.parent as Outro;
			
			var threshold:Threshold = new Threshold("y", ">", outro.blimpHit, 10);
			threshold.entered.addOnce(knockPlayerOff);
			outro.player.add(threshold);
			
			_bombChain = new ActionChain(this);
			_bombChain.addAction( new CallFunctionAction( baronSayLine ) );
			_bombChain.addAction( new CallFunctionAction( moveOverPlayer ) );
			_bombChain.addAction( new WaitAction(1) );
			_bombChain.addAction( new CallFunctionAction( readyBomb ) );
			_bombChain.addAction( new WaitAction(1.5) );
			_bombChain.addAction( new CallFunctionAction( dropBomb ) );
			_bombChain.addAction( new WaitAction(0.2) );
			_bombChain.addAction( new CallFunctionAction( bombAway ) );
			_bombChain.addAction( new WaitAction(1.5) );
			_bombChain.addAction( new CallFunctionAction( retryBomb ) );
			_bombChain.execute();
			
		}
		
		private function baronSayLine():void
		{
			_lineNum++;
			var outro:Outro = this.parent as Outro;
			
			CharUtils.setAnim(outro.baron, Place);
			
			Dialog(outro.baron.get(Dialog)).sayById("bomb"+_lineNum);
		}
		
		private function moveOverPlayer():void{
			var outro:Outro = this.parent as Outro;
			var offsetX:Number = 0;
			
			if(_lineNum == 1){
				//offsetX = 70;
			}
			
			TweenUtils.entityTo(outro.fokker, Spatial, 2, {x:Spatial(outro.player.get(Spatial)).x + offsetX, ease:Cubic.easeInOut});
		}
		
		private function readyBomb():void
		{
			var outro:Outro = this.parent as Outro;
		}
		
		private function dropBomb():void
		{
			AudioUtils.play(this, THROW);
			var outro:Outro = this.parent as Outro;
			CharUtils.setAnim(outro.baron, Throw);
		}
		
		private function retryBomb():void{
			var outro:Outro = this.parent as Outro;
			if(!hitplayer){
				if(_lineNum == 1){
					outro.firstMiss();
				}
				if(_lineNum < 3){
					bombPlayer();
				} else {
					rushPlayer();
				}
			}
		}
		
		private function bombAway():void{
			AudioUtils.play(this, BOMB);
			var outro:Outro = this.parent as Outro;
			
			var projectile:Entity = outro["junk"+_lineNum] as Entity;
			
			//projectile.remove(Motion);
			
			var wSpatial:Spatial = projectile.get(Spatial);
			var bSpatial:Spatial = outro.baron.get(Spatial);
			var pSpatial:Spatial = outro._airplaneB.get(Spatial);
			
			wSpatial.x = bSpatial.x + pSpatial.x;
			wSpatial.y = bSpatial.y + pSpatial.y;
			
			var hazardHitData:HazardHitData = new HazardHitData();
			hazardHitData.knockBackCoolDown = 0;
			hazardHitData.knockBackVelocity = new Point(400, 400);
			hazardHitData.velocityByHitAngle = false;
			
			var hit:Hazard = new Hazard();
			hit.boundingBoxOverlapHitTest = true;
			hit.velocity = new Point(0, 500);
			//hit.velocityByHitAngle = true;
			
			projectile.add(hit);
			
			Display(projectile.get(Display)).visible = true;
			
			TweenUtils.entityTo(projectile, Spatial, 1, {y:wSpatial.y + 350, onComplete:bounceWrench, ease:Cubic.easeIn});
		}
		
		private function bounceWrench():void{
			AudioUtils.stop(this, BOMB);
			AudioUtils.play(this, BOUNCE);
			
			// bounce wrench off of blimp
			var outro:Outro = this.parent as Outro;
			var motion:Motion = new Motion();
			var projectile:Entity = outro["junk"+_lineNum] as Entity;
			//projectile.remove(Hazard);
			
			if(hitplayer){
				motion.velocity = new Point(0, 600);
			} else {
				motion.velocity = new Point(0, -300);
			}
			
			motion.acceleration.y = 600;
			motion.rotationVelocity = 100;
			
			projectile.add(motion);
		}
		
		private function rushPlayer():void{
			var outro:Outro = this.parent as Outro;
			var actChain:ActionChain = new ActionChain(this);
			/*actChain.addAction( new CallFunctionAction( positionForRush ) );
			actChain.addAction( new WaitAction(2.5) );
			actChain.addAction( new CallFunctionAction( readyRush ) );
			actChain.addAction( new WaitAction(1.5) );*/
			actChain.addAction( new CallFunctionAction( rush ) );
			actChain.addAction( new WaitAction(0.5) );
			actChain.addAction( new CallFunctionAction( lookBack ) );
			actChain.addAction( new WaitAction(0.5) );
			actChain.addAction( new CallFunctionAction( endGame ) );
			actChain.addAction( new CallFunctionAction( Command.create( CharUtils.setDirection, outro.baron, true ) ) );
			
			actChain.execute();
		}
		
		private function positionForRush():void{
			var outro:Outro = this.parent as Outro;
			Dialog(outro.baron.get(Dialog)).sayById("rush");
			TweenUtils.entityTo(outro.fokker, Spatial, 3, {x:Spatial(outro.blimp.get(Spatial)).x - 500, y:540, ease:Cubic.easeInOut});
		}
		
		private function readyRush():void{
			var outro:Outro = this.parent as Outro;
			
			// not working?
			var hit:Hazard = new Hazard();
			hit.boundingBoxOverlapHitTest = true;
			outro.fokker.add(hit);
			
			CharUtils.setDirection(outro.baron, true);
		}
		
		public function hitPlayer():void{
			AudioUtils.play(this, HIT);
			
			var outro:Outro = this.parent as Outro;
			var projectile:Entity = outro["junk"+_lineNum] as Entity;
			projectile.remove(Hazard);
		}
		
		public function knockPlayerOff():void{
			hitplayer = true;
			
			_bombChain.clearActions();
			
			var outro:Outro = this.parent as Outro;
			outro.player.remove(Threshold);
			var projectile:Entity = outro["junk"+_lineNum] as Entity;
			projectile.remove(Hazard);
			
			outro.shellApi.completeEvent(outro.ftue.FELL_OFF_BLIMP);
			outro.shellApi.track(outro.ftue.FELL_OFF_BLIMP);
			
			outro.removeEntity(outro.blimpHit);
			
			SceneUtil.lockInput(outro);
			
			// quickly move blimp to catch player
			var spatial:Spatial = outro.blimp.get(Spatial);
			TweenUtils.entityTo(outro.blimp, Spatial, 1.4, {x:Spatial(outro.player.get(Spatial)).x, y:spatial.y + 200});
			
			// baron laughs and flies off
			CharUtils.setAnim(outro.baron, Laugh);
			
			var actChain:ActionChain = new ActionChain(this);
			actChain.addAction( new WaitAction(0.5) );
			actChain.addAction( new CallFunctionAction( rush ) );
			actChain.addAction( new WaitAction(0.5) );
			actChain.addAction( new CallFunctionAction( lookBack ) );
			actChain.addAction( new WaitAction(1) );
			actChain.addAction( new CallFunctionAction( Command.create( CharUtils.setDirection, outro.baron, true ) ) );
			actChain.addAction( new CallFunctionAction( outro.catchPlayer ) );
			
			actChain.execute();
		}
		
		private function rush():void{
			var outro:Outro = this.parent as Outro;
			
			
			TweenUtils.entityTo(outro.fokker, Spatial, 2, {x:shellApi.camera.viewportWidth / 2 + 1800, y:540, ease:Cubic.easeInOut});
		}
		
		private function lookBack():void{
			// look back at player and laugh
			var outro:Outro = this.parent as Outro;
			CharUtils.setDirection(outro.baron, false);
			CharUtils.setAnim(outro.baron, Laugh);
		}
		
		private function endGame():void{
			var outro:Outro = this.parent as Outro;
			outro.shellApi.completeEvent(outro.ftue.DODGED_BARON_SUCCESS);
			outro.shellApi.track(outro.ftue.DODGED_BARON_SUCCESS);
			if(!hitplayer)outro.endGame();
		}
		
		public var hitplayer:Boolean;
		
		private const BOUNCE:String = SoundManager.EFFECTS_PATH + "ls_hollow_plastic_02.mp3";
		private const THROW:String = SoundManager.EFFECTS_PATH + "whoosh_08.mp3";
		private const BOMB:String = SoundManager.EFFECTS_PATH + "object_fall_01.mp3";
		private const HIT:String = SoundManager.EFFECTS_PATH + "whack_02.mp3";
		
		private var _lineNum:int = 0;
		private var _fokkerBombSystem:FokkerBombSystem;
		private var _bombChain:ActionChain;
	}
}
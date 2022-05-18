package game.scenes.virusHunter.shared.components
{
	import flash.utils.Dictionary;
	
	import ash.core.Component;
	import engine.components.Spatial;
	
	public class DamageTarget extends Component
	{
		public function DamageTarget()
		{
			
		}
		
		public var isTriggered:Boolean = false;
		public var damage:Number = 0;
		public var maxDamage:Number = 1;
		public var damageFactor:Dictionary;
		public var lastPointOfImpact:Spatial;
		public var cooldown:Number;
		public var cooldownWait:Number = 0;
		public var isHit:Boolean = false;
		public var deathExplosions:Number = 4;
		public var deathExplosionWait:Number = 0;
		public var reactToInvulnerableWeapons:Boolean = true;
		public var hitParticleColor1:uint = 0;
		public var hitParticleColor2:uint = 0;
		public var hitParticleVelocity:uint = 1;
	}
}
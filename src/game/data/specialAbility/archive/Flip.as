// Status: retired
// Usage (1) ads
// Used by avatar item ad_caprisun2013_flip

package game.data.specialAbility.character 
{
	import com.greensock.easing.Quad;
	
	import ash.core.Entity;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.util.Command;
	
	import game.data.animation.Animation;
	import game.data.animation.entity.character.Score;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.util.CharUtils;
	import game.util.TweenUtils;
	

	public class Flip extends SpecialAbility
	{
		private const _jumpHeight:Number = 500;
		private const _jumpDuration:Number = 0.4 ;

		override public function activate( node:SpecialAbilityNode ):void
		{
			// TODO :: probably want to check if the characetr is stateDriven, and if so what state they are in, 
			// then only allow ability to be call from certain states
			if ( !super.data.isActive )
			{
				var _parentEntity:Entity = node.entity
				CharUtils.lockControls( node.entity, true, true);
				_parentEntity.get(Motion).velocity.y = -1200;
				_parentEntity.get(Motion).velocity.x = 0;
				startY = _parentEntity.get(Spatial).y;
				startX = _parentEntity.get(Spatial).x;
				phase = "jump";
				super.setActive( true );
			}
		}
		
		private function onLand():void
		{
			var motion:Motion = super.entity.get( Motion );
			var spatial:Spatial = super.entity.get( Spatial );
			spatial.rotation = 0;
			motion.rotationAcceleration = 0;
			CharUtils.setAnim( super.entity, Score );
			CharUtils.getTimeline( super.entity ).handleLabel( Animation.LABEL_ENDING, endAnim );
		}

		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			var motion:Motion = entity.get( Motion );
			var spatial:Spatial = entity.get( Spatial );
			spatial.x = startX;
			switch (phase)
			{
				case "jump":
					// when near top
					if (spatial.y < startY - 300)
						motion.rotationVelocity = 1200;
					// when reach top
					if (spatial.y < startY - 400)
						phase = "flip1";
					break;
				
				case "flip1":
					// if completed one flip
					if (spatial.rotation > 0)
						phase = "flip2a";
					break;
				
				case "flip2a":
					if (spatial.rotation < 0)
					{
						phase = "flip2b";
						motion.rotationAcceleration = -300;
					}
					break;
				
				case "flip2b":
					if ((spatial.rotation > 0) || (motion.velocity.y == 0))
					{
						phase = "fall";
						spatial.rotation = 0;
						motion.rotationVelocity = 0;
						motion.rotationAcceleration = 0;
						motion.velocity.y = 0;
						var tween:Tween = entity.get(Tween);
						if( !tween)
							entity.add( new Tween() );
						TweenUtils.entityTo( entity, Spatial, _jumpDuration, { y:startY, ease:Quad.easeIn, repeat:0, onComplete:onLand} );
					}
					break;
				
				case "fall":
					break;
					
			}
			super.update(node);
		}

		private function endAnim():void
		{
			// revert to previous animation
			CharUtils.stateDrivenOn( super.entity );
			CharUtils.lockControls( super.entity, false, false );
			
			super.setActive( false );
		}
		
		private var startY:Number;
		private var startX:Number;
		private var phase:String;
	}
}
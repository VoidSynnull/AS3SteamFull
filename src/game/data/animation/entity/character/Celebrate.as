package game.data.animation.entity.character 
{
	
	import com.greensock.easing.Quad;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.character.animation.RigAnimation;
	import game.util.CharUtils;
	import game.util.ClassUtils;
	import game.util.TweenUtils;
	
	/**
	 * ...
	 * @author Bard
	 */
	public class Celebrate extends Default
	{	
		private const LABEL_TRIGGER:String = "trigger";
		private const LABEL_FALL:String = "fall";
		private const _jumpHeight:Number = 160;
		private const _jumpDuration:Number = .4;
		
		public function Celebrate()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "celebrate" + ".xml";
		}
		
		override public function addComponentsTo(entity:Entity):void
		{
			var tween:Tween = entity.get(Tween);
			if( !tween)
			{
				entity.add( new Tween() );
			}
			
			if(entity.has(FSMControl) )
			{
				CharUtils.stateDrivenOff( entity );
			}
		}
		
		override public function reachedFrameLabel( entity:Entity, label:String ):void
		{
			//check label
			if ( label == LABEL_TRIGGER )
			{
				startJump( entity );
			}
		}
		
		private function startJump( entity:Entity ):void
		{
			var spatial:Spatial = entity.get(Spatial);
			TweenUtils.entityTo( entity, Spatial, _jumpDuration, { y:spatial.y - _jumpHeight, ease:Quad.easeOut, yoyo:true, repeat:1, onComplete:Command.create(onLand,entity) } );
		}
		
		private function onLand( entity:Entity ):void
		{
			var rigAnim:RigAnimation = entity.get( RigAnimation );
			if(entity.has(FSMControl) )
			{
				rigAnim.queue.push( Land );
				CharUtils.stateDrivenOn( entity );
			}
			else
			{
				rigAnim.queue.push( Land );
				rigAnim.queue.push( ClassUtils.getClassByObject(rigAnim.previous) );
			}
			rigAnim.manualEnd = true;
		}
	}
}
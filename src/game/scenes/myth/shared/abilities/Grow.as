package game.scenes.myth.shared.abilities
{
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Motion;
	import engine.group.Group;
	
	import game.components.motion.ScaleTarget;
	import game.data.game.GameEvent;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.motion.ScaleSystem;
	import game.util.CharUtils;
	
	public class Grow extends SpecialAbility
	{				
		override public function init( node:SpecialAbilityNode ):void
		{
			addComponentsTo(node.entity);
			node.owning.group.addSystem(new ScaleSystem());
		}
		
		override public function activate( node:SpecialAbilityNode ):void
		{
			group = node.owning.group;
			
			if(  !group.shellApi.checkEvent( "zeus_appears_throne" ))
			{
				group.shellApi.triggerEvent( "cannot_use_hades" );
			}
			else
			{
				var motion:Motion = group.shellApi.player.get( Motion );
				
				if( motion.velocity.x == 0 && motion.velocity.y == 0 )
				{
					_scaleIndex++;
				
					if(_scaleIndex == _scales.length)
					{
						_scaleIndex = 0;
					}
					
					var scaleTarget:ScaleTarget = node.entity.get(ScaleTarget);
					scaleTarget.target = _scales[_scaleIndex];
				
					
					group.shellApi.triggerEvent( "size_transform" );
				}
			}
		}
		
		override public function removeSpecial(node:SpecialAbilityNode):void
		{
			var id:Id = node.entity.get( Id );
			if( id )
			{
				if( id.id == "hades" || id.id == "playerDummy" )
				{
					removeComponents( node.entity );
				}
				else
				{
					super.removeSpecial( node );
				}
			}
			else
			{
				super.removeSpecial( node );
			}
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{
			CharUtils.setScale(node.entity, _scales[0]);
		}
		
		override protected function addComponentsTo(entity:Entity):void
		{
			var scaleTarget:ScaleTarget = new ScaleTarget();
			
			entity.add(scaleTarget);
			
			super.components = new Array();
			super.components.push(ScaleTarget);
		}
		
		private var group:Group;
		private var _scaleIndex:Number = 0;
		private var _scales:Array = [.4, .6];
	}
}
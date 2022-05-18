package game.scenes.survival1.shared.systems
{	
	import engine.components.Id;
	
	import game.data.motion.time.FixedTimestep;
	import game.scenes.survival1.shared.nodes.TriggerHitNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class TriggerHitSystem extends GameSystem
	{
		public function TriggerHitSystem()
		{
			super( TriggerHitNode, updateNode );
			super._defaultPriority = SystemPriorities.moveComplete;
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		public function updateNode( node:TriggerHitNode, time:Number ):void
		{
			var playerOff:Boolean = true;
			if( node.entityList.entities.length > 0 )
			{
				if( !node.animatedHit.active )
				{
					var name:String;
					var triggerId:String;
					
					for each( name in node.entityList.entities )
					{
						for each( triggerId in node.animatedHit.validEntities )
						{
							if( triggerId == name )
							{
								node.animatedHit.active = true;
								if( node.animatedHit.visualTimeline )
								{
									if( !node.animatedHit.visualTimeline.playing )
									{
										node.animatedHit.visualTimeline.play();
									}
								}
								
								if( node.animatedHit.triggered )
								{
									node.animatedHit.triggered.dispatch();
								}
								if( node.animatedHit.triggerAfterAnimation )
								{
									node.animatedHit.visualTimeline.handleLabel( "ending", node.animatedHit.triggerAfterAnimation );
								}
							}
						}
					}
				}
			}
			
			for each( name in node.entityList.entities )
			{
				if( name == "player" )
				{
					playerOff = false;
				}
			}
			
			if( playerOff )
			{
				if( node.animatedHit.offTriggered && node.animatedHit.active )
				{
					var id:Id = node.entity.get( Id );
					node.animatedHit.offTriggered.dispatch();
					node.animatedHit.active = false;
				}
			}
			
			if( node.entityList.entities.length == 0 )
			{
				if( node.animatedHit.active )
				{
//					for each( id in node.entityList.entities )
//					{
//						for each( triggerId in node.animatedHit.validEntities )
//						{
//							if( triggerId == id )
//							{
								node.animatedHit.active = false;
								if( node.animatedHit.offTriggered )
								{
									node.animatedHit.offTriggered.dispatch();
								}
							}
//						}
//					}
//				}
			}
		}
	}
}
package game.systems.entity.character.part
{
	import flash.display.MovieClip;
	
	import ash.tools.ListIteratingSystem;
	
	import game.components.entity.character.part.TribePart;
	import game.data.profile.TribeData;
	import game.nodes.entity.character.part.TribePartNode;
	import game.systems.SystemPriorities;
	import game.util.TribeUtils;


	
	/**
	 * <b>Author: Bard McKinley</b>
	 * 
	 */
	public class TribePartSystem extends ListIteratingSystem
	{
		public function TribePartSystem()
		{
			super(TribePartNode, updateNode);
			super._defaultPriority = SystemPriorities.render;
		}

		private function updateNode(node:TribePartNode, time:Number):void
		{
			var index:int;
			var tribeData:TribeData = TribeUtils.getTribeByEntity( node.parent.parent );
			if( !tribeData )
			{
				index = TribeUtils.tribeTotal;	// if tribe not defined, go to last frame which should be non-tribe
			}
			else
			{
				index = tribeData.index;
			}
			
			// set movieclip to index
			var clip:MovieClip =  node.tribePart.instanceData.getInstanceFrom( node.display.displayObject ) as MovieClip;
			//var clip:MovieClip = MovieClip(node.display.displayObject).active_object;	// TODO :: Temp until we can pass params along with components
			if( clip )
			{
				clip.gotoAndStop( index + 1 );	// add one to account for timeline index startting at 1	
				
				// once clip has been set component is no longer necessary
				node.entity.remove( TribePart );
			}
		}
	}
}

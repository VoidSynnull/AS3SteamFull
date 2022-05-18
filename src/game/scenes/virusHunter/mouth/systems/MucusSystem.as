package game.scenes.virusHunter.mouth.systems
{
	import flash.display.MovieClip;
	import flash.geom.ColorTransform;
	import flash.utils.Dictionary;
	
	import ash.core.Engine;
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Motion;
	import engine.group.Group;
	
	import game.components.entity.Sleep;
	import game.managers.EntityPool;
	import game.scenes.virusHunter.mouth.components.Mucus;
	import game.scenes.virusHunter.mouth.nodes.MucusNode;
	import game.util.EntityUtils;
	
	public class MucusSystem extends ListIteratingSystem
	{
		public function MucusSystem( group:Group, pool:EntityPool, total:Dictionary )
		{
			super( MucusNode, updateNode );
			_group = group;
			_pool = pool;
			_total = total;
			
			MAIN_COLORS.push( 0x0000FF00 ); 
			MAIN_COLORS.push( 0xFF7FFF00 );  
			MAIN_COLORS.push( 0x00F4A460 );
			ALT_COLORS.push( 0xFF00FF00 );
			ALT_COLORS.push( 0xFF556B2F );
			ALT_COLORS.push( 0xFFF4A460 );
		}
		
		private function updateNode( node:MucusNode, time:Number ):void
		{
			var mucusComp:Mucus = node.mucus;
			
			if( !mucusComp.init )
			{
				initMucus( node );
			}
			
			else
			{
				var motion:Motion = node.motion;
				motion.velocity.y = MIN_SPEED + ( Math.random() * TOP_SPEED_VAR );
				
				if( node.spatial.y > MAX_HEIGHT )
				{
					releaseNode( node );
				}
			}
		
		}
		
		private function initMucus( node:MucusNode ):void
		{
			var mucusComp:Mucus = node.mucus;
			var side:int = Math.round( Math.random() + 1);
			
			node.spatial.scaleX += Math.random();
			node.spatial.scaleY += Math.random();
			
			if( side == 1 )
			{
				EntityUtils.position( node.entity, X_START, Y_START );
			}
			else
			{
				node.spatial.scaleX *= -1;
			}
			
			var color:Number = Math.round( Math.random() * 3 );
			
			if( color != 3 )
			{
				mucusComp.innerDisplay = MovieClip( EntityUtils.getDisplayObject( node.entity )).contents.inner;
				mucusComp.innerDisplay.transform.colorTransform = hexToRGB( ALT_COLORS[ color ] );
			
				mucusComp.outerDisplay = MovieClip( EntityUtils.getDisplayObject( node.entity )).contents.outer;
				mucusComp.outerDisplay.transform.colorTransform = hexToRGB( MAIN_COLORS[ color ] );
			}
			
			mucusComp.init = true;
		}
		
		private function hexToRGB( hex:Number ):ColorTransform
		{
			var color:ColorTransform = new ColorTransform();
			color.redOffset = (hex >> 16) & 0xFF;
			color.greenOffset = (hex >> 8) & 0xFF;
			color.blueOffset = hex & 0xFF;
			return color;
		}
		
		private function releaseNode( node:MucusNode ):void
		{
			var sleep:Sleep = node.entity.get(Sleep);
			sleep.sleeping = true;
			node.entity.ignoreGroupPause = true;
			if( _pool.release( node.entity, "mucus" ))
			{
				_total[ "mucus" ]--;
			}
		}
		
		override public function addToEngine( systemManager:Engine ):void
		{
			super.addToEngine( systemManager );
		}
		
		override public function removeFromEngine( systemManager:Engine ):void
		{
			systemManager.releaseNodeList( MucusNode );
			super.removeFromEngine( systemManager );
		}
		
		private var _group:Group;
		private var _pool:EntityPool;
		private var _total:Dictionary;
		
		private const MAX_HEIGHT:uint = 2100;
		private const TOP_SPEED_VAR:uint = 80;
		private const MIN_SPEED:uint = 150;
		private const X_START:uint = 580;
		private const Y_START:int = -20;
		
		private const MAIN_COLORS:Vector.<uint> = new Vector.<uint>;
		private const ALT_COLORS:Vector.<uint> = new Vector.<uint>;
		
	}
}


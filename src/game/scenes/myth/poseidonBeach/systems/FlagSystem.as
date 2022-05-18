package game.scenes.myth.poseidonBeach.systems
{
	import flash.display.Sprite;
	
	import engine.components.Display;
	
	import game.scenes.myth.poseidonBeach.components.FlagComponent;
	import game.scenes.myth.poseidonBeach.nodes.FlagNode;
	import game.systems.GameSystem;
	import game.util.BitmapUtils;
	
	public class FlagSystem extends GameSystem
	{
		public function FlagSystem( )
		{
			super( FlagNode, updateNode );
		}
		
		private function updateNode( node:FlagNode, time:Number ):void
		{
			var flag:FlagComponent = node.flag;
			var display:Display = node.display;
			
			updateFlag( flag );
			
			var d:Sprite = display.displayObject as Sprite;
			d.graphics.clear();
				
			d.graphics.lineStyle( 2, 0x4E4737 );
			d.graphics.beginFill( 0x4CA389 );
			d.graphics.moveTo( flag.points[ 0 ].x, flag.points[ 0 ].y );
			
			d.graphics.curveTo( flag.points[ 1 ].x, flag.points[ 1 ].y, flag.points[ 2 ].x, flag.points[ 2 ].y );
			d.graphics.curveTo( flag.points[ 3 ].x, flag.points[ 3 ].y, flag.points[ 5 ].x, flag.points[ 5 ].y );
			d.graphics.curveTo( flag.points[ 4 ].x, flag.points[ 4 ].y, flag.points[ 0 ].x, flag.points[ 0 ].y );	
				
			if ( Math.random()*30 < 1 ) {
				flag.speed = Math.random( )* 0.2 + 0.2;
			}
			BitmapUtils.convertContainer(d,1);
		}
		
		private function updateFlag( flag:FlagComponent ):void
		{
			var number:int;
			
			for( number = 1; number < 5; number ++ )
			{
				flag.timers[ number ] += flag.speed;
				flag.points[ number ].y = flag.startY[ number ] + 5 + 20 * Math.sin( flag.timers[ number ]);
			}
		}
	}
}
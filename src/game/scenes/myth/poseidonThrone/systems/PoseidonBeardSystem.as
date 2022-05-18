package game.scenes.myth.poseidonThrone.systems
{
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.myth.poseidonThrone.components.PoseidonBeardComponent;
	import game.scenes.myth.poseidonThrone.nodes.PoseidonBeardNode;
	import game.systems.GameSystem;
	import game.util.EntityUtils;
	
	public class PoseidonBeardSystem extends GameSystem
	{
		public function PoseidonBeardSystem()
		{
			super( PoseidonBeardNode, updateNode, initBeard );
			super.fixedTimestep = 1/30;
		}
		
		private function updateNode( node:PoseidonBeardNode, time:Number ):void
		{
			var entity:Entity = node.entity;
			var beard:PoseidonBeardComponent = node.beard;
			var display:Display = node.display;
			var mustachioNum:Number;
			var number:Number;
			var clip:MovieClip;
			var pClip:MovieClip;
			
			var point:Spatial;
			var target:Spatial;
			
			for( mustachioNum = 0; mustachioNum < 4; mustachioNum ++ )
			{
				clip = MovieClip( EntityUtils.getDisplayObject( entity ).getChildByName( "mustachio" + mustachioNum ));
				beard.timers[ mustachioNum ] += time;
				
				for( number = 1; number < 6; number ++ )
				{
					pClip = MovieClip( clip.getChildByName( "p" + number  ));
					
					point = beard.mustachio[ mustachioNum ][ number ];
					target = beard.mustachio[ mustachioNum ][ number - 1 ];
					
					point.rotation = 0.2 * Math.sin( beard.timers[ mustachioNum ]);
					point.x = target.x - beard.radius * Math.cos( target.rotation );
					point.y = target.y - beard.radius * Math.sin( target.rotation );
					point.rotation += target.rotation;
					
					pClip.x = point.x;
					pClip.y = point.y;
					pClip.rotation = point.rotation;
				}
			}
			
			drawBeard( node );
		}
		
		private function initBeard( node:PoseidonBeardNode ):void
		{
			var entity:Entity = node.entity;
			var beard:PoseidonBeardComponent = node.beard;

			var timer:int;
			var number:int;
			var mustachioNum:int;
			var clip:MovieClip;
			var point:MovieClip;
			var spatial:Spatial;
			
			
			for( mustachioNum = 0; mustachioNum < 4; mustachioNum ++ )
			{
				timer = 0;
				if( mustachioNum == 0 || mustachioNum == 1 )
				{
					timer = 2 * Math.PI / 3;
				}
				
				beard.timers.push( timer );
				beard.mustachio.push( new Vector.<Spatial>);
				
				clip = MovieClip( EntityUtils.getDisplayObject( entity ).getChildByName( "mustachio" + mustachioNum ));
	
				for( number = 0; number < 6; number ++ )
				{
					point = MovieClip( clip.getChildByName( "p" + number ));
					spatial = new Spatial( point.x, point.y );
					spatial.rotation = point.rotation;
					
					beard.mustachio[ mustachioNum ].push( spatial );
				}
			}
		}
		
		private function drawBeard( node:PoseidonBeardNode ):void
		{
			var display:Display = node.display;
			var beard:PoseidonBeardComponent = node.beard;
			var entity:Entity = node.entity;
			var clip:MovieClip;
			var lineWidth:Number;
			var deltaX:Number;
			var deltaY:Number;
			var number:Number;
			var mustachioNum:Number;
			
			for( mustachioNum = 0; mustachioNum < 4; mustachioNum ++ )
			{
				clip = MovieClip( EntityUtils.getDisplayObject( entity ).getChildByName( "mustachio" + mustachioNum ));
				clip.graphics.clear();
				lineWidth = beard.thickness;
				clip.graphics.lineStyle( lineWidth, 0 );
				clip.graphics.moveTo( beard.mustachio[ mustachioNum ][ 0 ].x, beard.mustachio[ mustachioNum ][ 0 ].y );
				
				for( number = 0; number < 5; number ++ )
				{
					lineWidth -= 1.5;
					clip.graphics.lineStyle( lineWidth, 0x216778 );
					deltaX = ( beard.mustachio[ mustachioNum ][ number ].x + beard.mustachio[ mustachioNum ][ number + 1 ].x ) / 2;
					deltaY = ( beard.mustachio[ mustachioNum ][ number ].y + beard.mustachio[ mustachioNum ][ number + 1 ].y ) / 2;
					
					clip.graphics.curveTo( beard.mustachio[ mustachioNum ][ number ].x, beard.mustachio[ mustachioNum ][ number ].y, deltaX, deltaY );
				}
			}
		}
	}
}
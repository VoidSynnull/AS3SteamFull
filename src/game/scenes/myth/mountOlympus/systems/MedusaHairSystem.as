package game.scenes.myth.mountOlympus.systems
{
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.myth.mountOlympus.components.MedusaHairComponent;
	import game.scenes.myth.mountOlympus.nodes.MedusaHairNode;
	import game.systems.GameSystem;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	
	public class MedusaHairSystem extends GameSystem
	{
		public function MedusaHairSystem( )
		{
			super( MedusaHairNode, updateNode, initHair );
			super.fixedTimestep = 1/30;
		}
		
		private function updateNode( node:MedusaHairNode, time:Number ):void
		{
			//Draw code is intense on mobile. Only draw the snake bodies once.
			if(PlatformUtils.isMobileOS && node.hair.drawOnce)
			{
				if(!node.hair.drawnOnce)
				{
					node.hair.drawnOnce = true;
				}
				else
				{
					node.entity.remove(MedusaHairComponent);
					return;
				}
			}
			
			var hair:MedusaHairComponent = node.hair;
			var entity:Entity = node.entity;
			var display:Display = node.display;
			var snakeNum:Number;
			var number:Number;
			var clip:MovieClip;
			var pClip:MovieClip;
			
			var point:Spatial;
			var target:Spatial;
			
			for( snakeNum = 0; snakeNum < hair.snake.length; snakeNum ++ )
			{
				clip = MovieClip( EntityUtils.getDisplayObject( entity ).getChildByName( "snake" + snakeNum ));
				if( !clip )
				{
					clip = MovieClip( EntityUtils.getDisplayObject( entity ));
				}
				
				hair.timers[ snakeNum ] += time;
				
				if( hair.state[ snakeNum ] == hair.LICK || hair.state[ snakeNum ] == hair.RETURN )
				{
					showTongue( node, snakeNum );
				}
					
				for( number = 1; number < 5; number ++ )
				{
					pClip = MovieClip( clip.getChildByName( "p" + number  ));
					
					point = hair.snake[ snakeNum ][ number ];
					target = hair.snake[ snakeNum ][ number - 1 ];
					
					point.rotation = Math.sin( hair.timers[ snakeNum ]);
					point.x = target.x - hair.radius * Math.cos( target.rotation );
					point.y = target.y - hair.radius * Math.sin( target.rotation );
					point.rotation += target.rotation;
					
					pClip.x = point.x;
					pClip.y = point.y;
					pClip.rotation = point.rotation;
				}
			}
			
			drawHair( node );
		}
		
		private function initHair( node:MedusaHairNode ):void
		{
			if( node.id.id != "medusaSnake" )
			{
				var entity:Entity = node.entity;
				var hair:MedusaHairComponent = node.hair;
				
				var timer:Number;
				var speed:Number;
				var number:int;
				var snakeNum:int;
				var clip:MovieClip;
				var point:MovieClip;
				var spatial:Spatial;
				
				for( snakeNum = 0; snakeNum < 8; snakeNum ++ )
				{
					hair.radius = Math.random() * 10 + 15;
					
					speed = Math.random() * .025 + .02;
					timer = ( Math.random() * 3 ) * Math.PI - snakeNum;
					hair.timers.push( timer );
					
					hair.snake.push( new Vector.<Spatial>);
					hair.speeds.push( speed );
					clip = MovieClip( EntityUtils.getDisplayObject( entity ).getChildByName( "snake" + snakeNum ));
					
					for( number = 0; number < 5; number ++ )
					{
						point = MovieClip( clip.getChildByName( "p" + number ));
						spatial = new Spatial( point.x, point.y );
						spatial.rotation = point.rotation;
						
						hair.snake[ snakeNum ].push( spatial );
						if( number == 4 )
						{
							point.visible = false;
						}
					}
					
					hair.head.push( MovieClip( clip.getChildByName( "head" )));
					hair.state.push( hair.IDLE );
					
					MovieClip( hair.head[ snakeNum ].getChildByName( "tongue" )).scaleX = 0;
				}
			}
		}
		
		private function drawHair( node:MedusaHairNode ):void
		{
			var display:Display = node.display;
			var hair:MedusaHairComponent = node.hair;
			var entity:Entity = node.entity;
			var clip:MovieClip;
			var lineWidth:Number;
			var deltaX:Number;
			var deltaY:Number;
			var number:Number;
			var snakeNum:Number;
			
			for( snakeNum = 0; snakeNum < hair.snake.length; snakeNum ++ )
			{
				clip = MovieClip( EntityUtils.getDisplayObject( entity ).getChildByName( "snake" + snakeNum ));
				if( !clip )
				{
					clip = MovieClip( EntityUtils.getDisplayObject( entity ));
				}
				
				clip.graphics.clear();
				lineWidth = hair.thickness;
				clip.graphics.lineStyle( lineWidth, 0x3C4C33 );
				clip.graphics.moveTo( hair.snake[ snakeNum ][ 0 ].x, hair.snake[ snakeNum ][ 0 ].y );
				
				for( number = 0; number < 4; number ++ )
				{
					lineWidth -= 1;
					clip.graphics.lineStyle( lineWidth, 0x3C4C33 );
					deltaX = ( hair.snake[ snakeNum ][ number ].x + hair.snake[ snakeNum ][ number + 1 ].x ) / 2;
					deltaY = ( hair.snake[ snakeNum ][ number ].y + hair.snake[ snakeNum ][ number + 1 ].y ) / 2;
					
					clip.graphics.curveTo( hair.snake[ snakeNum ][ number ].x, hair.snake[ snakeNum ][ number ].y, deltaX, deltaY );
				}
				
				lineWidth = hair.thickness - 5;
				
				clip.graphics.lineStyle( lineWidth, 0x799766 );
				clip.graphics.moveTo( hair.snake[ snakeNum ][ 0 ].x, hair.snake[ snakeNum ][ 0 ].y );
				
				for( number = 0; number < 4; number ++ )
				{
					lineWidth -= 1;
					clip.graphics.lineStyle( lineWidth, 0x799766 );
					
					deltaX = ( hair.snake[ snakeNum ][ number ].x + hair.snake[ snakeNum ][ number + 1 ].x ) / 2;
					deltaY = ( hair.snake[ snakeNum ][ number ].y + hair.snake[ snakeNum ][ number + 1 ].y ) / 2;
					
					clip.graphics.curveTo( hair.snake[ snakeNum ][ number ].x, hair.snake[ snakeNum ][ number ].y, deltaX, deltaY );
				}
				
				hair.head[ snakeNum ].x = ( hair.snake[ snakeNum ][ 3 ].x + hair.snake[ snakeNum ][ 4 ].x ) / 2;
				hair.head[ snakeNum ].y = ( hair.snake[ snakeNum ][ 3 ].y + hair.snake[ snakeNum ][ 4 ].y ) / 2;
				hair.head[ snakeNum ].rotation = -clip.rotation;
				
				if ( Math.random() * 30 < 1 )
				{
					hair.state[ snakeNum ] = hair.LICK;
				}
			}
		}
		
		private function showTongue( node:MedusaHairNode, snakeNum:int ):void
		{
			var hair:MedusaHairComponent = node.hair;
			var clip:MovieClip = MovieClip (hair.head[ snakeNum ].getChildByName( "tongue" ));
		
			if( hair.state[ snakeNum ] == hair.LICK )
			{
				clip.scaleX += ( 1 - clip.scaleX ) / 4;
				if ( clip.scaleX > .98) 
				{
					hair.state[ snakeNum ] = hair.RETURN;
				}
			}
			
			else
			{
				clip.scaleX -= clip.scaleX / 4;
				if( clip.scaleX < .02 )
				{
					hair.state[ snakeNum ] = hair.IDLE;
				}
			}
		}
	}
}
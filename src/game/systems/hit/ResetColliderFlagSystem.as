package game.systems.hit
{
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.components.hit.CurrentHit;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.entity.collider.BitmapCollisionNode;
	import game.nodes.entity.collider.PlatformReboundCollisionNode;
	import game.nodes.entity.collider.PlatformCollisionNode;
	import game.nodes.hit.HitEntityListNode;
	import game.nodes.hit.MovieClipHitNode;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;
	
	public class ResetColliderFlagSystem extends System
	{
		public function ResetColliderFlagSystem()
		{
			super._defaultPriority = SystemPriorities.resetColliderFlags;
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		/**
		 * reset these flags here (outside of ALL hit/motion systems).  It will get set to true on the next pass of the 
		 *   hit systems if an entity is still hitting it.
		 */
		override public function update(time:Number):void
		{
			var platformCollisionNode:PlatformCollisionNode;
			
			for(platformCollisionNode = _platformCollisionNodes.head; platformCollisionNode; platformCollisionNode = platformCollisionNode.next)
			{
				updatePlatformCollisionNode(platformCollisionNode, time);
			}
			
			var bitmapCollisionNode:BitmapCollisionNode;
			
			for(bitmapCollisionNode = _bitmapCollisionNodes.head; bitmapCollisionNode; bitmapCollisionNode = bitmapCollisionNode.next)
			{
				updateBitmapCollisionNode(bitmapCollisionNode, time);
			}
			
			var movieClipHitNode:MovieClipHitNode;
			
			for(movieClipHitNode = _movieClipHitNodes.head; movieClipHitNode; movieClipHitNode = movieClipHitNode.next)
			{
				updateMovieClipHitNode(movieClipHitNode, time);
			}
			
			var hitEntityListNode:HitEntityListNode;
			
			for(hitEntityListNode = _hitEntityListNodes.head; hitEntityListNode; hitEntityListNode = hitEntityListNode.next)
			{
				updateHitEntityListNode(hitEntityListNode, time);
			}
			
			var bouncePlatformCollisionNode:PlatformReboundCollisionNode;
			
			for(bouncePlatformCollisionNode = _bouncePlatformCollisionNodes.head; bouncePlatformCollisionNode; bouncePlatformCollisionNode = bouncePlatformCollisionNode.next)
			{
				updateBouncePlatformCollisionNode(bouncePlatformCollisionNode, time);
			}
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			_platformCollisionNodes = systemManager.getNodeList(PlatformCollisionNode);
			_bitmapCollisionNodes = systemManager.getNodeList(BitmapCollisionNode);
			_movieClipHitNodes = systemManager.getNodeList(MovieClipHitNode);
			_hitEntityListNodes = systemManager.getNodeList(HitEntityListNode);
			_bouncePlatformCollisionNodes = systemManager.getNodeList(PlatformReboundCollisionNode);
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			_platformCollisionNodes = null;
			_bitmapCollisionNodes = null;
			_movieClipHitNodes = null;
			_hitEntityListNodes = null;
			_bouncePlatformCollisionNodes = null;
			
			systemManager.releaseNodeList(HitEntityListNode);
			
			super.removeFromEngine(systemManager);
		}
		
		private function updateHitEntityListNode(node:HitEntityListNode, time:Number):void
		{
			node.hits.entities.length = 0;
		}
		
		private function updateMovieClipHitNode(node:MovieClipHitNode, time:Number):void
		{
			if (!EntityUtils.sleeping(node.entity))
			{
				node.hit.isHit = false;
			}
		}
				
		private function updatePlatformCollisionNode(node:PlatformCollisionNode, time:Number):void
		{
			if (!EntityUtils.sleeping(node.entity))
			{
				node.collider.isHit = false;
				node.collider.baseGround = false;
				if(node.currentHit != null) { node.currentHit.hit = null; }
			}
		}
		
		private function updateBouncePlatformCollisionNode(node:PlatformReboundCollisionNode, time:Number):void
		{
			if (!EntityUtils.sleeping(node.entity))
			{
				node.collider.isHit = false;
				if(node.currentHit != null) { node.currentHit.hit = null; }
			}
		}
		
		private function updateBitmapCollisionNode(node:BitmapCollisionNode, time:Number):void
		{
			if (!EntityUtils.sleeping(node.entity))
			{
				node.collider.color = 0;
				node.collider.hitX = NaN;
				node.collider.hitY = NaN;
				
				node.collider.centerColor = 0;
				node.collider.centerHitX = NaN;
				node.collider.centerHitY = NaN;
			}
		}
		
		private var _platformCollisionNodes:NodeList;
		private var _bitmapCollisionNodes:NodeList;
		private var _movieClipHitNodes:NodeList;
		private var _hitEntityListNodes:NodeList;
		private var _bouncePlatformCollisionNodes:NodeList;
	}
}
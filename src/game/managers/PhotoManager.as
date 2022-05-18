package game.managers
{
	import com.poptropica.AppConfig;
	
	import flash.utils.Dictionary;
	
	import engine.Manager;
	
	import game.data.character.LookData;
	import game.proxy.DataStoreRequest;
	import game.util.Utils;

	public class PhotoManager extends Manager
	{
		public function PhotoManager()
		{
			reset();
		}
		
		/**
		 * Adds photo to set of taken photos, if not already there
		 * @param photo
		 * @param setId
		 * @return - returns true if photo is added, false if photo was laready there
		 */
		public function take(photoId:String, setId:String, lookData:LookData = null):Boolean
		{
			if(_takenPhotos[setId] == null)
			{
				reset(setId);
			}
			
			var photos:Vector.<String> = _takenPhotos[setId];
			if (photos.indexOf(photoId) == -1)
			{
				// NOTE :: Nothing actually checks for valid photoId, must be done prior to calling this method
				photos.push(photoId);
				savePhoto(photoId,setId,lookData);	
				return(true);
			}
			else
			{
				// already taken
				return(false);
			}
		}
		
		/**
		 * FOR DEBUG :: Remove a photo from set of taken photos, saves to profile if successfully removed
		 * @param photo
		 * @param setId
		 */
		public function remove(photo:String, setId:String):void
		{
			if(_takenPhotos[setId] != null)
			{
				var photos:Vector.<String> = _takenPhotos[setId];
				var index:Number = photos.indexOf(photo);
				
				if (index > -1)
				{
					photos.splice(index, 1);
					// save to profile
					shellApi.profileManager.active.photos[setId] = Utils.convertVectorToArray(photos);
					shellApi.profileManager.save();
				}
			}
		}
				
		/**
		 * Checks if photo if photos has been taken
		 * @param photo - id of photo
		 * @param setId - set photo is part of (generally island id)
		 * @return - will return true if valid photo that has not been taken 
		 */
		public function checkIsTaken(photo:String, setId:String):Boolean
		{
			var alreadyTaken:Boolean = false;
			if(_takenPhotos[setId] != null) 
			{
				var photos:Vector.<String> = _takenPhotos[setId];
				alreadyTaken = (photos.indexOf(photo) > -1);
			}

			trace("PhotoManager::check() found", photo, "has", (alreadyTaken ? "already" : "not yet"), "been taken");
			return alreadyTaken;
		}
		
		/**
		 * Updates PhotoManager to reflect photos within given Dictionary.
		 * This is called when restoring profile, so that PhotoManager is in sync with profile data
		 * @param profilePhotos - Dictionary of sets of photos, generally given from profile data
		 * @param setId - if setId is not specified will restore all sets
		 */
		public function restore( profilePhotos:Dictionary, setId:String = null):void
		{
			var total:Number;
			var photos:Array;
			var index:uint = 0;
			var nextSetId:String;
			
			if(setId != null)
			{
				photos = profilePhotos[setId];
				total = photos.length;
				
				for(index = 0 ; index < total; index++)
				{
					take(photos[index], setId);
				}
			}
			else
			{
				for(nextSetId in profilePhotos)
				{
					photos = profilePhotos[nextSetId];
					total = photos.length;
					
					for(index = 0 ; index < total; index++)
					{
						take(photos[index], nextSetId);
					}
				}
			}
		}

		/**
		 * Resets set of photos 
		 * @param setID - set of photo (generally island id)
		 */
		public function reset(setID:String=null):void
		{
			if (null == setID) {
				_takenPhotos = new Dictionary();
			} else {
				_takenPhotos[setID] = new Vector.<String>;
			}
		}
		
		/**
		 * Save photos stored within PhotoManager to ProfileManager 
		 * @param setId
		 */
		private function savePhoto(photoId:String, setId:String, lookData:LookData):void
		{
			// save to profile
			if(shellApi.profileManager.active.photos[setId] == null)
			{
				shellApi.profileManager.active.photos[setId] = new Array();
			}
			shellApi.profileManager.active.photos[setId] = Utils.convertVectorToArray(_takenPhotos[setId]);
			shellApi.profileManager.save();
			
			// save externally
			// save photo to server (if applicable)
			if (true)
			{ 
				// no need to deal with LSO I believe, since this is only available for users
				shellApi.siteProxy.store(DataStoreRequest.scenePhotoStorageRequest(photoId, setId, lookData));	// what if the DataStoreRequest was delivered as an argument? _RAM
			}
		}
		
		/**
		 * Save photos stored within PhotoManager to ProfileManager 
		 * @param setId
		 */
		private function removePhoto(photoId:String, setId:String):void
		{
			
		}
		
		/** Stores taken photos, Dictionary of Arrays, using setId as key (generally island id) */
		private var _takenPhotos:Dictionary;
	}
}
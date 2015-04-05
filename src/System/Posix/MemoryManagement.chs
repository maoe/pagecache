{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE CApiFFI #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE ViewPatterns #-}
module System.Posix.MemoryManagement
  ( mmap
  , munmap
  , madvise
  , posixMadvise
  , mlock
  , munlock
  , mprotect
  , msync
  , mincore

  , Protection
  , pattern PROT_NONE
  , pattern PROT_READ
  , pattern PROT_WRITE
  , pattern PROT_EXEC

  , Sharing
  , pattern MAP_SHARED
  , pattern MAP_PRIVATE

  , Advice
  , pattern MADV_NORMAL
  , pattern MADV_SEQUENTIAL
  , pattern MADV_RANDOM
  , pattern MADV_WILLNEED
  , pattern MADV_DONTNEED
  , pattern MADV_FREE
  , pattern MADV_ZERO_WIRED_PAGES

  , PosixAdvice
  , pattern POSIX_MADV_NORMAL
  , pattern POSIX_MADV_SEQUENTIAL
  , pattern POSIX_MADV_RANDOM
  , pattern POSIX_MADV_WILLNEED
  , pattern POSIX_MADV_DONTNEED

  , Residency
  , pattern MINCORE_INCORE
  , pattern MINCORE_REFERENCED
  , pattern MINCORE_MODIFIED
  , pattern MINCORE_REFERENCED_OTHER
  , pattern MINCORE_MODIFIED_OTHER

  , SyncFlags
  , pattern MS_ASYNC
  , pattern MS_SYNC
  , pattern MS_INVALIDATE
  ) where

import Foreign
import Foreign.C

import Data.Vector.Storable (Vector)
import System.Posix.Types
import qualified Data.Vector.Storable as V

#include <sys/mman.h>
#include <unistd.h>

newtype Protection = Protection { unProtection :: CInt } deriving Eq

instance Monoid Protection where
  mempty = PROT_NONE
  mappend (Protection p1) (Protection p2) = Protection (p1 .|. p2)

pattern PROT_NONE :: Protection
pattern PROT_NONE <- ((\p -> unProtection p .&. _PROT_NONE > 0) -> True)
  where
    PROT_NONE = Protection _PROT_NONE

pattern PROT_READ :: Protection
pattern PROT_READ <- ((\p -> unProtection p .&. _PROT_READ > 0) -> True)
  where
    PROT_READ = Protection _PROT_READ

pattern PROT_WRITE :: Protection
pattern PROT_WRITE <- ((\p -> unProtection p .&. _PROT_WRITE > 0) -> True)
  where
    PROT_WRITE = Protection _PROT_WRITE

pattern PROT_EXEC :: Protection
pattern PROT_EXEC <- ((\p -> unProtection p .&. _PROT_EXEC > 0) -> True)
  where
    PROT_EXEC = Protection _PROT_EXEC

_PROT_NONE, _PROT_READ, _PROT_WRITE, _PROT_EXEC :: CInt
_PROT_NONE = {# const PROT_NONE #}
_PROT_READ = {# const PROT_READ #}
_PROT_WRITE = {# const PROT_WRITE #}
_PROT_EXEC = {# const PROT_EXEC #}

newtype Sharing = Sharing { unSharing :: CInt } deriving (Eq, Show)

pattern MAP_SHARED :: Sharing
pattern MAP_SHARED = Sharing {# const MAP_SHARED #}

pattern MAP_PRIVATE :: Sharing
pattern MAP_PRIVATE = Sharing {# const MAP_PRIVATE #}

newtype Residency = Residency { unResidency :: CUChar } deriving Storable

instance Show Residency where
  show (Residency n) = show n

pattern MINCORE_INCORE :: Residency
pattern MINCORE_INCORE <-
  ((\r -> unResidency r .&. _MINCORE_INCORE > 0) -> True)
  where
    MINCORE_INCORE = Residency _MINCORE_INCORE

pattern MINCORE_REFERENCED :: Residency
pattern MINCORE_REFERENCED <-
  ((\r -> unResidency r .&. _MINCORE_REFERENCED > 0) -> True)
  where
    MINCORE_REFERENCED = Residency _MINCORE_REFERENCED

pattern MINCORE_MODIFIED :: Residency
pattern MINCORE_MODIFIED <-
  ((\r -> unResidency r .&. _MINCORE_MODIFIED > 0) -> True)
  where
    MINCORE_MODIFIED = Residency _MINCORE_MODIFIED

pattern MINCORE_REFERENCED_OTHER :: Residency
pattern MINCORE_REFERENCED_OTHER <-
  ((\r -> unResidency r .&. _MINCORE_REFERENCED_OTHER > 0) -> True)
  where
    MINCORE_REFERENCED_OTHER = Residency _MINCORE_REFERENCED_OTHER

pattern MINCORE_MODIFIED_OTHER :: Residency
pattern MINCORE_MODIFIED_OTHER <-
  ((\r -> unResidency r .&. _MINCORE_MODIFIED_OTHER > 0) -> True)
  where
    MINCORE_MODIFIED_OTHER = Residency _MINCORE_MODIFIED_OTHER

_MINCORE_INCORE :: CUChar
_MINCORE_INCORE = {# const MINCORE_INCORE #}
_MINCORE_REFERENCED, _MINCORE_MODIFIED :: CUChar
_MINCORE_REFERENCED = {# const MINCORE_REFERENCED #}
_MINCORE_MODIFIED = {# const MINCORE_MODIFIED #}
_MINCORE_REFERENCED_OTHER, _MINCORE_MODIFIED_OTHER :: CUChar
_MINCORE_REFERENCED_OTHER = {# const MINCORE_REFERENCED_OTHER #}
_MINCORE_MODIFIED_OTHER = {# const MINCORE_MODIFIED_OTHER #}

mmap
  :: Ptr a
  -> CSize
  -> Protection
  -> Sharing
  -> Fd
  -> COff
  -> IO (Ptr a)
mmap ptr size protection sharing fd offset = do
  p <- throwErrnoIf (== _MAP_FAILED) "mmap" $
    {# call mmap as _mmap #}
      (castPtr ptr)
      (fromIntegral size)
      (unProtection protection)
      (unSharing sharing)
      (fromIntegral fd)
      (fromIntegral offset)
  return $! castPtr p

foreign import capi "sys/mman.h value MAP_FAILED" _MAP_FAILED :: Ptr a

munmap
  :: Ptr a
  -> CSize
  -> IO ()
munmap ptr size = throwErrnoIfMinus1_ "munmap" $
  {# call munmap as _munmap #} (castPtr ptr) (fromIntegral size)

newtype Advice = Advice { unAdvice :: CInt } deriving (Eq, Show)

pattern MADV_NORMAL :: Advice
pattern MADV_NORMAL = Advice {# const MADV_NORMAL #}

pattern MADV_SEQUENTIAL :: Advice
pattern MADV_SEQUENTIAL = Advice {# const MADV_SEQUENTIAL #}

pattern MADV_RANDOM :: Advice
pattern MADV_RANDOM = Advice {# const MADV_RANDOM #}

pattern MADV_WILLNEED :: Advice
pattern MADV_WILLNEED = Advice {# const MADV_WILLNEED #}

pattern MADV_DONTNEED :: Advice
pattern MADV_DONTNEED = Advice {# const MADV_DONTNEED #}

pattern MADV_FREE :: Advice
pattern MADV_FREE = Advice {# const MADV_FREE #}

pattern MADV_ZERO_WIRED_PAGES :: Advice
pattern MADV_ZERO_WIRED_PAGES = Advice {# const MADV_ZERO_WIRED_PAGES #}

newtype PosixAdvice = PosixAdvice { unPosixAdvice :: CInt } deriving (Eq, Show)

pattern POSIX_MADV_NORMAL :: PosixAdvice
pattern POSIX_MADV_NORMAL = PosixAdvice {# const POSIX_MADV_NORMAL #}

pattern POSIX_MADV_SEQUENTIAL :: PosixAdvice
pattern POSIX_MADV_SEQUENTIAL = PosixAdvice {# const POSIX_MADV_SEQUENTIAL #}

pattern POSIX_MADV_RANDOM :: PosixAdvice
pattern POSIX_MADV_RANDOM = PosixAdvice {# const POSIX_MADV_RANDOM #}

pattern POSIX_MADV_WILLNEED :: PosixAdvice
pattern POSIX_MADV_WILLNEED = PosixAdvice {# const POSIX_MADV_WILLNEED #}

pattern POSIX_MADV_DONTNEED :: PosixAdvice
pattern POSIX_MADV_DONTNEED = PosixAdvice {# const POSIX_MADV_DONTNEED #}

madvise :: Ptr a -> CSize -> Advice -> IO ()
madvise ptr size advice =
  throwErrnoIfMinus1_ "madvise" $
    {# call madvise as _madvise #}
      (castPtr ptr) (fromIntegral size) (unAdvice advice)

posixMadvise :: Ptr a -> CSize -> PosixAdvice -> IO ()
posixMadvise ptr size advice =
  throwErrnoIfMinus1_ "posix_madvise" $
    {# call posix_madvise as _posix_madvise #}
      (castPtr ptr) (fromIntegral size) (unPosixAdvice advice)

mincore :: Ptr a -> CSize -> IO (Vector Residency)
mincore ptr size = do
  pageSize <- {# call sysconf #} {# const _SC_PAGESIZE #}
  let !pages = fromIntegral $ (fromIntegral size + pageSize - 1) `div` pageSize
  fptr <- mallocForeignPtrBytes pages
  withForeignPtr fptr $ \p ->
    throwErrnoIf_ (/= 0) "mincore" $
      {# call mincore as _mincore #}
        (castPtr ptr) (fromIntegral size) (castPtr p)
  return $! V.unsafeFromForeignPtr0 fptr pages

mlock :: Ptr a -> CSize -> IO ()
mlock ptr size = throwErrnoIfMinus1_ "mlock" $
  {# call mlock as _mlock #} (castPtr ptr) (fromIntegral size)

munlock :: Ptr a -> CSize -> IO ()
munlock ptr size = throwErrnoIfMinus1_ "munlock" $
  {# call munlock as _munlock #} (castPtr ptr) (fromIntegral size)

mprotect :: Ptr a -> CSize -> Protection -> IO ()
mprotect ptr size protection = throwErrnoIfMinus1_ "mprotect" $
  {# call mprotect as _mprotect #}
    (castPtr ptr) (fromIntegral size) (unProtection protection)

newtype SyncFlags = SyncFlags { unSyncFlags :: CInt }

pattern MS_ASYNC :: SyncFlags
pattern MS_ASYNC <- ((\flags -> unSyncFlags flags .&. _MS_ASYNC > 0) -> True)
  where
    MS_ASYNC = SyncFlags _MS_ASYNC

pattern MS_SYNC :: SyncFlags
pattern MS_SYNC <- ((\flags -> unSyncFlags flags .&. _MS_SYNC > 0) -> True)
  where
    MS_SYNC = SyncFlags _MS_SYNC

pattern MS_INVALIDATE :: SyncFlags
pattern MS_INVALIDATE <-
  ((\flags -> unSyncFlags flags .&. _MS_INVALIDATE > 0) -> True)
  where
    MS_INVALIDATE = SyncFlags _MS_INVALIDATE

_MS_ASYNC, _MS_SYNC, _MS_INVALIDATE :: CInt
_MS_ASYNC = {# const MS_ASYNC #}
_MS_SYNC = {# const MS_SYNC #}
_MS_INVALIDATE = {# const MS_INVALIDATE #}

msync :: Ptr a -> CSize -> SyncFlags -> IO ()
msync ptr size flags = throwErrnoIfMinus1_ "msync" $
  {# call msync as _msync #}
    (castPtr ptr) (fromIntegral size) (unSyncFlags flags)

using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using UnityEngine;

namespace TCA.Assets
{
    public interface ITcaAssetProvider : IDisposable
    {
        Task<Sprite> LoadSpriteAsync(string address, CancellationToken cancellationToken = default);

        Task PreloadSpritesAsync(IEnumerable<string> addresses, CancellationToken cancellationToken = default);
    }
}
